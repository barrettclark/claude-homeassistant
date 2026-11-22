#!/usr/bin/env python3
"""Generate a host/SDL harness from an ESPHome LVGL device config.

Copies the device's lvgl: block, swaps HA/hardware sensors for template
sensors with fixed sample values (keeping their on_value actions), and
renders headless to BMP via snapshot.take so layouts can be checked
without flashing hardware.

Usage:
  python tools/lvgl_harness.py esphome/rack-display.yaml [--out DIR] [--run]
"""

import argparse
import copy
import os
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

# Sample values keyed by sensor id; anything missing gets a default.
SAMPLE_NUMERIC = {
    "rack_temp": 78.4,
    "outside_temp": 58.3,
    "outside_humidity": 62,
    "outside_wind": 7,
    "outside_pressure": 29.92,
    "nas_vol1_used": 71,
    "nas_vol2_used": 43,
    "nas_vol1_temp": 95,
    "nas_vol2_temp": 97,
    "nas_cpu": 12,
    "nas_mem": 38,
    "net_devices": 47,
    "net_download": 1234,
    "net_upload": 210,
    "manhattan_cpu": 23,
    "manhattan_mem": 61,
    "manhattan_swap": 8,
    "manhattan_temp": 113,
    "ups_charge": 100,
    "ups_load": 18,
    "ups_voltage": 121,
}
SAMPLE_TEXT = {
    "outside_condition": "partlycloudy",
    "ups_status": "OL CHRG",
    "manhattan_uptime": "12d 4h",
    "nas_uptime": "41d 19h",
}
# Worst-case widths and offline states.
EDGE_NUMERIC = {
    "rack_temp": 104.6, "outside_temp": -12.4, "outside_humidity": 100,
    "outside_wind": 38, "outside_pressure": 30.12, "nas_vol1_used": 100,
    "nas_vol2_used": 0, "nas_vol1_temp": 131, "nas_vol2_temp": 128,
    "nas_cpu": 100, "nas_mem": 99, "net_devices": 188, "net_download": 98765,
    "net_upload": 43210, "manhattan_cpu": "NAN", "manhattan_mem": "NAN",
    "manhattan_swap": "NAN", "manhattan_temp": "NAN", "ups_charge": 7,
    "ups_load": 100, "ups_voltage": 0,
}
EDGE_TEXT = {
    "outside_condition": "lightning-rainy", "ups_status": "OB LB",
    "manhattan_uptime": "unavailable", "nas_uptime": "365d 23h",
}


class Tagged:
    def __init__(self, tag, value):
        self.tag, self.value = tag, value


class Loader(yaml.SafeLoader):
    pass


def _construct_tagged(loader, tag_suffix, node):
    if isinstance(node, yaml.ScalarNode):
        return Tagged("!" + tag_suffix, loader.construct_scalar(node))
    if isinstance(node, yaml.SequenceNode):
        return Tagged("!" + tag_suffix, loader.construct_sequence(node, deep=True))
    return Tagged("!" + tag_suffix, loader.construct_mapping(node, deep=True))


Loader.add_multi_constructor("!", _construct_tagged)


class Dumper(yaml.SafeDumper):
    pass


def _represent_tagged(dumper, data):
    if isinstance(data.value, str):
        style = "|" if "\n" in data.value else None
        return dumper.represent_scalar(data.tag, data.value, style=style)
    if isinstance(data.value, list):
        return dumper.represent_sequence(data.tag, data.value)
    return dumper.represent_mapping(data.tag, data.value)


def _represent_str(dumper, data):
    style = "|" if "\n" in data else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style=style)


Dumper.add_representer(Tagged, _represent_tagged)
Dumper.add_representer(str, _represent_str)


def _template(entry, value, text):
    out = {"platform": "template", "id": entry["id"]}
    lit = f'return std::string("{value}");' if text else f"return {value};"
    out["lambda"] = Tagged("!lambda", lit)
    # Short interval so on_value fires soon after boot.
    out["update_interval"] = "1s"
    if "on_value" in entry:
        out["on_value"] = copy.deepcopy(entry["on_value"])
    return out


def _widget_ids(node, acc):
    if isinstance(node, dict):
        if isinstance(node.get("id"), str):
            acc.add(node["id"])
        for v in node.values():
            _widget_ids(v, acc)
    elif isinstance(node, list):
        for v in node:
            _widget_ids(v, acc)
    return acc


def _prune_actions(entry, ids):
    """Drop lvgl.*.update actions targeting widgets not on the page (partial builds)."""
    on_value = entry.get("on_value")
    if not on_value:
        return entry
    then = on_value.get("then", []) if isinstance(on_value, dict) else on_value
    kept = [a for a in then
            if not (isinstance(a, dict) and len(a) == 1
                    and next(iter(a)).startswith("lvgl.")
                    and next(iter(a.values())).get("id") not in ids)]
    if kept:
        entry["on_value"] = {"then": kept}
    else:
        entry.pop("on_value")
    return entry


def build(device_cfg, name, snapshot_delay, edge=False):
    numeric = EDGE_NUMERIC if edge else SAMPLE_NUMERIC
    text = EDGE_TEXT if edge else SAMPLE_TEXT
    lvgl = copy.deepcopy(device_cfg["lvgl"])
    ids = _widget_ids(lvgl, set())
    lvgl.pop("touchscreens", None)
    lvgl["displays"] = ["rack_display"]

    sensors = []
    for s in device_cfg.get("sensor", []):
        if "id" not in s:
            continue
        sensors.append(_prune_actions(
            _template(s, numeric.get(s["id"], 50), False), ids))
    text_sensors = []
    for s in device_cfg.get("text_sensor", []):
        if "id" not in s:
            continue
        text_sensors.append(_prune_actions(
            _template(s, text.get(s["id"], "sample"), True), ids))

    cfg = {
        "esphome": {
            "name": name,
            "on_boot": {
                "priority": -100,
                "then": [
                    {"delay": snapshot_delay},
                    {"snapshot.take": {"id": "rack_display", "filename": "page"}},
                    {"lambda": Tagged("!lambda", "exit(0);")},
                ],
            },
        },
        "host": {},
        "logger": {"level": "INFO"},
        "time": [{"platform": "host", "id": "ha_time"}],
        "display": [{
            "platform": "sdl",
            "id": "rack_display",
            "headless": True,
            "auto_clear_enabled": False,
            "update_interval": "never",
            "dimensions": {"width": 800, "height": 480},
        }],
        "sensor": sensors,
        "text_sensor": text_sensors,
        "lvgl": lvgl,
    }
    if "interval" in device_cfg:
        cfg["interval"] = device_cfg["interval"]
    return cfg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("config")
    ap.add_argument("--out", default="temp/harness")
    ap.add_argument("--name", default="lvgl-harness")
    ap.add_argument("--delay", default="4s")
    ap.add_argument("--edge", action="store_true", help="worst-case sample values")
    ap.add_argument("--run", action="store_true", help="compile, run, copy BMP")
    args = ap.parse_args()

    with open(args.config) as f:
        device_cfg = yaml.load(f, Loader=Loader)

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    harness = out / f"{args.name}.yaml"
    with open(harness, "w") as f:
        yaml.dump(build(device_cfg, args.name, args.delay, args.edge), f, Dumper=Dumper,
                  sort_keys=False, allow_unicode=True, width=1000)
    print(f"wrote {harness}")
    if not args.run:
        return 0

    subprocess.run(["esphome", "compile", str(harness)], check=True)
    binary = out / ".esphome" / "build" / args.name / ".pioenvs" / args.name / "program"
    snapdir = out / "snapshots"
    shutil.rmtree(snapdir, ignore_errors=True)
    snapdir.mkdir()
    env = dict(os.environ, ESPHOME_SNAPSHOT_DIR=str(snapdir.resolve()))
    subprocess.run([str(binary)], env=env, timeout=60)
    shots = sorted(snapdir.glob("*"))
    for s in shots:
        png = s.with_suffix(".png")
        subprocess.run(["sips", "-s", "format", "png", str(s), "--out", str(png)],
                       check=True, capture_output=True)
        print(f"snapshot: {png.resolve()}")
    return 0 if shots else 1


if __name__ == "__main__":
    sys.exit(main())
