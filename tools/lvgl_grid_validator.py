#!/usr/bin/env python3
"""Static layout checks for an ESPHome LVGL config.

Catches the mistakes behind the rack-display rendering failures, all of
which pass `esphome config`/`compile`:
- LVGL's default theme pads every obj (~20px/side plus flex/grid gaps);
  fixed pixel budgets break unless `lvgl: theme: obj: pad_all: 0`.
- A widget `main:` block replaces all of the widget's top-level props
  (width/height/x/y...) in ESPHome, so the widget falls back to defaults.
- Grid tracks (+ gaps) that don't sum to the container's own size.
- Absolutely-placed children that extend past their parent.

It does not simulate rendering; use tools/lvgl_harness.py for that.

Usage: python tools/lvgl_grid_validator.py esphome/rack-display.yaml
"""

import sys
from pathlib import Path

import yaml

TOLERANCE_PX = 4  # small unused slop (rounding) is fine; large gaps are the bug


def esphome_yaml_loader():
    # ESPHome's YAML has custom tags (!secret, !include, !lambda, etc).
    # We only care about plain mappings/scalars for layout math, so make
    # every unknown tag parse as its scalar/sequence/mapping value.
    class Loader(yaml.SafeLoader):
        pass

    def passthrough(loader, tag_suffix, node):
        if isinstance(node, yaml.MappingNode):
            return loader.construct_mapping(node)
        if isinstance(node, yaml.SequenceNode):
            return loader.construct_sequence(node)
        return loader.construct_scalar(node)

    Loader.add_multi_constructor("!", passthrough)
    return Loader


def track_px(spec):
    """Resolve one grid_rows/grid_columns entry to a pixel int, or None if
    it's a unit we don't evaluate numerically (FR()/CONTENT - flagged
    separately as a warning, since those are exactly what broke before)."""
    if isinstance(spec, int):
        return spec
    if isinstance(spec, str):
        s = spec.strip().upper()
        if s.isdigit():
            return int(s)
    return None


def check_grid(node, path, errors, warnings):
    if not isinstance(node, dict):
        return
    layout = node.get("layout")
    if isinstance(layout, dict) and layout.get("type") in ("grid", "GRID"):
        rows = layout.get("grid_rows") or []
        cols = layout.get("grid_columns") or []
        pad_row = layout.get("pad_row", 0) or 0
        pad_col = layout.get("pad_column", 0) or 0

        for axis_name, specs, pad, declared in (
            ("row", rows, pad_row, node.get("height")),
            ("column", cols, pad_col, node.get("width")),
        ):
            pxs = [track_px(s) for s in specs]
            if any(p is None for p in pxs):
                warnings.append(
                    f"{path}: {axis_name} track uses FR()/CONTENT "
                    f"({specs}) — not numerically checked, and this is "
                    f"the unit class that caused silent zero-size bugs "
                    f"before. Prefer literal pixel ints."
                )
                continue
            gaps = max(len(pxs) - 1, 0) * pad
            total = sum(pxs) + gaps
            # height:1 + flex_grow is this file's idiom for "whatever
            # space is left after siblings" — not a literal pixel size,
            # so there's nothing to reconcile the grid tracks against.
            if declared == 1 and node.get("flex_grow"):
                continue
            if isinstance(declared, int):
                diff = declared - total
                if abs(diff) > TOLERANCE_PX:
                    errors.append(
                        f"{path}: {axis_name} tracks {pxs} + {gaps}px gaps "
                        f"= {total}px, but this container's own "
                        f"{'height' if axis_name == 'row' else 'width'} is "
                        f"declared as {declared}px (off by {diff}px)."
                    )

    # Recurse into widgets lists wherever they appear.
    for key, value in node.items():
        if key == "widgets" and isinstance(value, list):
            for child in value:
                if isinstance(child, dict):
                    for ctype, cval in child.items():
                        if isinstance(cval, dict):
                            check_grid(cval, f"{path}>{ctype}", errors, warnings)
        elif isinstance(value, dict):
            check_grid(value, f"{path}>{key}", errors, warnings)
        elif isinstance(value, list):
            for item in value:
                if isinstance(item, dict):
                    check_grid(item, f"{path}>{key}[]", errors, warnings)


def check_parts_and_bounds(node, path, size, errors):
    """size: (w, h) of node's content box when known literally, else None."""
    if not isinstance(node, dict):
        return
    if "main" in node:
        errors.append(f"{path}: has a `main:` block, which discards the widget's "
                      f"top-level width/height/x/y. Put main-part styles at top level.")
    has_layout = isinstance(node.get("layout"), dict)
    for child in node.get("widgets", []) or []:
        if not isinstance(child, dict):
            continue
        for ctype, c in child.items():
            if not isinstance(c, dict):
                continue
            cpath = f"{path}>{ctype}"
            w, h = c.get("width"), c.get("height")
            literal = isinstance(w, int) and isinstance(h, int)
            if size and literal and not has_layout:
                x, y = c.get("x", 0), c.get("y", 0)
                if "align" not in c and isinstance(x, int) and isinstance(y, int):
                    if x < 0 or y < 0 or x + w > size[0] or y + h > size[1]:
                        errors.append(f"{cpath}: box ({x},{y} {w}x{h}) exceeds parent "
                                      f"content area {size[0]}x{size[1]}.")
            inner = None
            if literal:
                bw = c.get("border_width", 2 if "card_style" in str(c.get("styles")) else 0)
                inner = (w - 2 * bw, h - 2 * bw)
            check_parts_and_bounds(c, cpath, inner, errors)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    yaml_path = Path(sys.argv[1])
    data = yaml.load(yaml_path.read_text(), Loader=esphome_yaml_loader())

    lvgl = data.get("lvgl")
    if not lvgl:
        print("No top-level 'lvgl:' key found — nothing to validate.")
        sys.exit(1)

    errors = []
    warnings = []
    for page in lvgl.get("pages", []):
        for widget in page.get("widgets", []):
            for wtype, wval in widget.items():
                if isinstance(wval, dict):
                    check_grid(wval, f"page_{page.get('id')}>{wtype}", errors, warnings)

    theme_obj = (lvgl.get("theme") or {}).get("obj") or {}
    if theme_obj.get("pad_all") != 0:
        errors.append("lvgl.theme.obj.pad_all is not 0: LVGL's default theme padding "
                      "will silently shrink every fixed-size container.")
    for page in lvgl.get("pages", []):
        check_parts_and_bounds(page, f"page_{page.get('id')}", (800, 480), errors)

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"FAIL  {e}")

    if errors:
        print(f"\n{len(errors)} layout problem(s) found.")
        sys.exit(1)
    print(f"OK — no layout problems found ({len(warnings)} warning(s)).")
    sys.exit(0)


if __name__ == "__main__":
    main()
