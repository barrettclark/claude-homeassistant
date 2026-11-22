# UPS Monitoring, Rack Display, and Trend Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the newly-added UPS (NUT integration, `sensor.office_ups_*` entities) real-time power-event notifications, a presence on the rack display, and a trend-graph view in the main HA dashboard.

**Architecture:** Three independent, mechanical YAML edits to an existing Home Assistant + ESPHome config repo. No new integrations, no new infrastructure. Each task touches exactly one file and is validated with this repo's existing validation tooling.

**Tech Stack:** Home Assistant YAML automations, ESPHome YAML (LVGL UI on an ESP32-S3 touch panel), HA Lovelace YAML dashboard (`history-graph`/`statistics-graph` built-in cards).

**Spec:** Design approved in conversation (no separate spec file — short design, see chat history 2026-11-21). Key facts carried from that design and from direct inspection of the running HA instance:
- UPS entities confirmed live: `sensor.office_ups_status` (state `Online`/`OL` when healthy), `sensor.office_ups_battery_charge` (`%`, `device_class: battery`), `sensor.office_ups_load` (`%`), `sensor.office_ups_input_voltage`, `sensor.office_ups_output_voltage`, `sensor.office_ups_alarms`.
- Existing blueprint automation `id: '1644196625324'` already does a *daily 10am* battery-class sweep — intentionally left untouched; the new automation is additive, for real-time power events only.
- Notify target used throughout this config: `notify.mobile_app_barrett_clarks_iphone_17_pro`.
- `esphome/rack-display.yaml` is a single-screen (no scroll) LVGL card grid; cards use shared `card_style`/`card_value_style` style definitions and a per-source color-group pattern (`card_border_<source>` / `card_title_<source>`). Barrett confirmed there's room to compact existing cards to fit more.
- `config/ui-lovelace.yaml` currently has exactly one view (`Home`); this plan adds a second.

## Global Constraints

- All python validation tools run via `source venv/bin/activate && python <tool_path>` (per project CLAUDE.md).
- Never push without validation passing (`make validate` / `python tools/run_tests.py`).
- No new HA integrations, no new secrets, no metrics server (explicitly decided against).
- Entity IDs copied exactly as confirmed live via the HA API — no guessing.
- ESPHome file has no local compiler available in this environment (`esphome` CLI not installed); validation for Task 2 is YAML-structure review plus a manual OTA flash/deploy by Barrett, not an automated compile step here.

## Review Focus

- **UPS status flapping:** NUT/USB polling can report a brief transition (e.g. `OL` → `OB` → `OL` within seconds) during a short line blip. The automation should not need special debounce logic per the design, but the "restored" message must only fire from a genuine prior "on battery" state, not on every poll — covered by using `from:`/`to:` state triggers (HA only fires on an actual value change, not on every poll).
- **Unknown/unavailable UPS entity at HA restart:** `sensor.office_ups_status` could briefly be `unknown` after a HA Core restart before the NUT integration's first poll. The trigger's `to:` value must not match `unknown`/`unavailable`, so the automation shouldn't misfire — covered by scoping the "away from Online" trigger to exclude those states explicitly.
- **Rack display overflow:** adding 3-4 new UPS cards to an already-full single screen risks introducing scroll or visual crowding, which was an explicit anti-goal. Covered by shrinking shared card dimensions, not by removing existing cards.
- **New Lovelace view entity typos:** a bad entity ID in a `history-graph`/`statistics-graph` card fails silently in the UI (card just shows nothing) rather than erroring validation. Covered by cross-checking every entity ID in the new view against the live `/api/states` list already captured in this conversation.
- **Blueprint automation collision:** the new automation must not accidentally also match/alert on the same battery-class entity via a second code path. Covered by this automation triggering on `sensor.office_ups_status` and `sensor.office_ups_battery_charge` directly by entity_id, not by a template that could overlap the blueprint's domain-wide scan.

---

### Task 1: UPS real-time notification automation

**Files:**
- Modify: `config/automations.yaml` (append new automation entry)
- Test: manual validation via project tooling (no HA instance test harness)

**Interfaces:**
- Consumes: `sensor.office_ups_status` (states: `Online`, `On Battery`, or similar NUT-mapped string — confirmed live value today is `Online`), `sensor.office_ups_battery_charge` (numeric `%` string state)
- Produces: nothing consumed by later tasks (independent)

- [ ] **Step 1: Write the new automation entry**

Append to `config/automations.yaml`, following the existing list-item style in that file (plain `trigger:`/`condition:`/`action:`/`mode:` keys, `id` as a unique string not colliding with existing ids):

```yaml
- id: 'ups_power_event'
  alias: UPS Power Event Notification
  description: Immediate notification when the office UPS goes on battery, returns to line power, or its charge drops low — real-time, unlike the daily battery-sweep blueprint.
  trigger:
  - platform: state
    entity_id: sensor.office_ups_status
    from: Online
    id: on_battery
  - platform: state
    entity_id: sensor.office_ups_status
    to: Online
    id: restored
  - platform: numeric_state
    entity_id: sensor.office_ups_battery_charge
    below: 20
    id: low_charge
  condition: []
  action:
  - choose:
    - conditions:
      - condition: trigger
        id: on_battery
      sequence:
      - service: notify.mobile_app_barrett_clarks_iphone_17_pro
        data:
          message: "UPS on battery — power may be out"
    - conditions:
      - condition: trigger
        id: restored
      sequence:
      - service: notify.mobile_app_barrett_clarks_iphone_17_pro
        data:
          message: "Power restored — UPS back online"
    - conditions:
      - condition: trigger
        id: low_charge
      sequence:
      - service: notify.mobile_app_barrett_clarks_iphone_17_pro
        data:
          message: "UPS battery low"
  mode: single
```

Note on the `from: Online` trigger: HA state triggers only fire on an actual change, so a `from: Online` trigger (with no `to:` constraint) fires on any transition away from `Online` — including to `unknown`/`unavailable` after a restart, which the Review Focus item above flags. Add `not_to: ["unknown", "unavailable"]` is not valid HA syntax for state triggers; instead constrain with a `condition:` on the `on_battery` branch checking the new state is a real value:

```yaml
    - conditions:
      - condition: trigger
        id: on_battery
      - condition: not
        conditions:
        - condition: state
          entity_id: sensor.office_ups_status
          state: unknown
      - condition: not
        conditions:
        - condition: state
          entity_id: sensor.office_ups_status
          state: unavailable
      sequence:
      - service: notify.mobile_app_barrett_clarks_iphone_17_pro
        data:
          message: "UPS on battery — power may be out"
```

- [ ] **Step 2: Validate YAML syntax and entity references**

Run: `source venv/bin/activate && python tools/yaml_validator.py && python tools/reference_validator.py`
Expected: both report no errors for `automations.yaml`; `reference_validator.py` confirms `sensor.office_ups_status` and `sensor.office_ups_battery_charge` resolve to real entities.

- [ ] **Step 3: Run full validation suite**

Run: `source venv/bin/activate && python tools/run_tests.py`
Expected: exits 0 / reports all validators passing, confirming the automation hook didn't break anything else.

- [ ] **Step 4: Commit**

```bash
git add config/automations.yaml
git commit -m "Add real-time UPS power-event notification automation"
```

---

### Task 2: Add UPS cards to the rack display

**Files:**
- Modify: `esphome/rack-display.yaml`

**Interfaces:**
- Consumes: `sensor.office_ups_status` (text), `sensor.office_ups_battery_charge` (%), `sensor.office_ups_load` (%), `sensor.office_ups_input_voltage` (V) — same four already confirmed live
- Produces: nothing consumed by later tasks (independent); follows the exact `homeassistant` sensor + `on_value` → `lvgl.label.update` pattern already used for `nas_*`/`net_*`/`manhattan_*` sensors in this file, and the `card_border_<source>`/`card_title_<source>` style-group pattern

- [ ] **Step 1: Add a UPS color-group style pair**

In the `lvgl: style_definitions:` block (after the existing `card_title_manhattan` entry, around line 404), add:

```yaml
    - id: card_border_ups
      border_color: 0xE57373
    - id: card_title_ups
      text_color: 0xE57373
      text_font: montserrat_10
```

(Red accent — distinct from the existing blue/orange/green/purple/cyan source colors, fitting for a power-status card.)

- [ ] **Step 2: Add four `homeassistant` sensor/text_sensor entries**

In the `sensor:` block, after the existing `manhattan_temp` entry (around line 331), add:

```yaml
  - platform: homeassistant
    id: ups_charge
    entity_id: sensor.office_ups_battery_charge
    on_value:
      then:
        - lvgl.label.update:
            id: ups_charge_label
            text: !lambda return str_sprintf("%.0f%%", id(ups_charge).state);

  - platform: homeassistant
    id: ups_load
    entity_id: sensor.office_ups_load
    on_value:
      then:
        - lvgl.label.update:
            id: ups_load_label
            text: !lambda return str_sprintf("%.0f%%", id(ups_load).state);

  - platform: homeassistant
    id: ups_voltage
    entity_id: sensor.office_ups_input_voltage
    on_value:
      then:
        - lvgl.label.update:
            id: ups_voltage_label
            text:
              format: "%.0fV"
              args:
                - id(ups_voltage).state
```

`sensor.office_ups_status` is a text state ("Online"), not numeric, so it goes in the existing `text_sensor:` block (after `outside_condition`, around line 341):

```yaml
  - platform: homeassistant
    id: ups_status
    entity_id: sensor.office_ups_status
    on_value:
      then:
        - lvgl.label.update:
            id: ups_status_label
            text: !lambda return id(ups_status).state;
```

- [ ] **Step 3: Add four card widgets to the home page grid**

In `lvgl: pages: - id: page_home: ... widgets:` card-grid list (after the existing `manhattan_temp_label` card, around line 777), add four cards following the exact structure of the existing cards (`obj:` with `styles: [card_style, card_border_ups]`, column-flex layout, title label + value label):

```yaml
                    - obj:
                        styles:
                          - card_style
                          - card_border_ups
                        layout:
                          type: flex
                          flex_flow: COLUMN
                          flex_align_main: CENTER
                          flex_align_cross: CENTER
                        widgets:
                          - label:
                              styles: card_title_ups
                              text: "UPS Status"
                          - label:
                              id: ups_status_label
                              styles: card_value_style
                              text: "--"
                    - obj:
                        styles:
                          - card_style
                          - card_border_ups
                        layout:
                          type: flex
                          flex_flow: COLUMN
                          flex_align_main: CENTER
                          flex_align_cross: CENTER
                        widgets:
                          - label:
                              styles: card_title_ups
                              text: "UPS Charge"
                          - label:
                              id: ups_charge_label
                              styles: card_value_style
                              text: "--%"
                    - obj:
                        styles:
                          - card_style
                          - card_border_ups
                        layout:
                          type: flex
                          flex_flow: COLUMN
                          flex_align_main: CENTER
                          flex_align_cross: CENTER
                        widgets:
                          - label:
                              styles: card_title_ups
                              text: "UPS Load"
                          - label:
                              id: ups_load_label
                              styles: card_value_style
                              text: "--%"
                    - obj:
                        styles:
                          - card_style
                          - card_border_ups
                        layout:
                          type: flex
                          flex_flow: COLUMN
                          flex_align_main: CENTER
                          flex_align_cross: CENTER
                        widgets:
                          - label:
                              styles: card_title_ups
                              text: "UPS Input"
                          - label:
                              id: ups_voltage_label
                              styles: card_value_style
                              text: "--V"
```

- [ ] **Step 4: Compact the shared card grid to keep the screen scroll-free**

The grid now holds 20 cards (16 existing + 4 UPS) on a single 800x480 panel. Reduce `card_style`'s `width`/`height` (currently `118`/`68`) and `card_grid_style`'s `pad_row`/`pad_column` (currently `8`/`8`) enough that 20 cards still fit without scrolling — exact values are a builder judgment call based on the panel's 800x480 resolution and a 5-per-row layout (minus the ~16px side padding and page-title row already in the page); start by trying `width: 108`, `height: 60`, `pad_row: 6`, `pad_column: 6` and adjust from there.

- [ ] **Step 5: Review YAML structure**

Run: `python3 -c "import yaml; yaml.safe_load(open('esphome/rack-display.yaml'))"`
Expected: no exception (confirms valid YAML syntax; this repo has no local ESPHome compiler, so full validation happens on Barrett's next OTA flash).

- [ ] **Step 6: Commit**

```bash
git add esphome/rack-display.yaml
git commit -m "Add UPS status/charge/load/voltage cards to rack display"
```

---

### Task 3: New "Rack Display" trend dashboard view

**Files:**
- Modify: `config/ui-lovelace.yaml` (append a second view)

**Interfaces:**
- Consumes: all entities already shown on the rack display — `sensor.rack_temp` equivalent HA-side entity (confirm exact id below), `weather.coppell` attributes are not directly graphable via `history-graph` (skip; rack display's weather page has no standalone HA sensor entities to graph — out of scope here, matches "Rack Display items" = NAS/network/Manhattan/UPS/rack-air, not Tempest), `sensor.boulevardier_*`, `sensor.192_0_2_1_devices_connected`, `sensor.rt_ac3100_4508_kib_s_received`/`_sent`, `sensor.office_192_0_2_200_*`, `sensor.office_ups_*`
- Produces: nothing (final task)

- [ ] **Step 1: Confirm the rack-air HA-side entity id**

The rack display's own DS18B20 temp (`id: rack_temp` in ESPHome) is a *local* sensor on the board — check whether it's also exposed back to HA as an entity (ESPHome boards publish their sensors to HA automatically via the `api:` connection). Run:

`curl -s -H "Authorization: Bearer $HA_TOKEN" "$HA_URL/api/states" | python3 -c "import sys,json; [print(e['entity_id']) for e in json.load(sys.stdin) if 'rack' in e['entity_id'].lower() or 'home_office_rack' in e['entity_id'].lower()]"`

(load `HA_TOKEN`/`HA_URL` from `.env` first, as done earlier in this conversation). Expected: one `sensor.*` entity for the rack temperature. Use that exact id in Step 2 below; if none exists, drop the rack-air card from the view (it only exists as a local ESPHome sensor, not an HA entity, and this task only adds HA-side dashboard cards).

- [ ] **Step 2: Append the new view**

Append to `config/ui-lovelace.yaml` (top-level `views:` list, as a sibling of the existing `- title: Home` entry):

```yaml
- title: Rack Display
  cards:
  - type: history-graph
    title: Rack Temperature
    hours_to_show: 24
    entities:
    - entity: <rack-air entity id from Step 1>
  - type: statistics-graph
    title: NAS (Boulevardier)
    days_to_show: 7
    entities:
    - sensor.boulevardier_volume_1_volume_used
    - sensor.boulevardier_volume_2_volume_used
    - sensor.boulevardier_volume_1_average_disk_temp
    - sensor.boulevardier_volume_2_average_disk_temp
    - sensor.boulevardier_cpu_utilization_total
    - sensor.boulevardier_memory_usage_real
  - type: history-graph
    title: Network
    hours_to_show: 24
    entities:
    - entity: sensor.192_0_2_1_devices_connected
    - entity: sensor.rt_ac3100_4508_kib_s_received
    - entity: sensor.rt_ac3100_4508_kib_s_sent
  - type: statistics-graph
    title: Manhattan
    days_to_show: 7
    entities:
    - sensor.office_192_0_2_200_cpu_usage
    - sensor.office_192_0_2_200_memory_usage
    - sensor.office_192_0_2_200_swap_usage
    - sensor.office_192_0_2_200_composite_temperature
  - type: history-graph
    title: UPS
    hours_to_show: 24
    entities:
    - entity: sensor.office_ups_battery_charge
    - entity: sensor.office_ups_load
    - entity: sensor.office_ups_input_voltage
    - entity: sensor.office_ups_status
```

(`statistics-graph` is used for the longer-retention groups where long-term stats add value over a week; `history-graph` for the shorter/at-a-glance groups — both are built-in HA card types, no custom cards.)

- [ ] **Step 3: Validate YAML syntax and entity references**

Run: `source venv/bin/activate && python tools/yaml_validator.py && python tools/reference_validator.py`
Expected: no errors; every entity id in the new view resolves.

- [ ] **Step 4: Run full validation suite**

Run: `source venv/bin/activate && python tools/run_tests.py`
Expected: all validators pass.

- [ ] **Step 5: Commit**

```bash
git add config/ui-lovelace.yaml
git commit -m "Add Rack Display trend view with history/statistics graphs"
```
