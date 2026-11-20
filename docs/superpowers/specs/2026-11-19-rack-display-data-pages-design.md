# Rack Display — Home Assistant Data Pages

## Intent

The rack display (`esphome/rack-display.yaml`) currently shows a single
bench-test page: a title and the rack-air DS18B20 temperature. Barrett
wants it to earn its place in the rack by surfacing status from the rest
of the homelab: the Synology NAS ("boulevardier"), the ASUS router, and
outside conditions (Tempest weather station), alongside the existing
rack-air reading — now in °F instead of °C.

## Goals

- Convert the existing rack-air temperature readout from °C to °F.
- Add HA-sourced data to the display: NAS stats, router stats, outside
  weather, and time.
- Keep the existing PIR/touch wake-on-activity behavior unchanged.
- Use data that already exists as real HA entities today — no new HA
  integrations as part of this change.

## Non-goals

- Beelink ("manhattan") stats via Beszel — no HA integration exists for
  Beszel; out of scope until that's built separately.
- UPS/battery status — no UPS entity exists in HA at all right now
  (confirmed: no NUT integration, no Synology UPS sensor). Nothing to
  show even once it's plugged in, until that's wired up HA-side.
- Per-SSID connected-device counts — confirmed by reading HA's `asuswrt`
  integration source (`device_tracker.py`, `router.py`, `bridge.py`):
  it tracks presence/IP/MAC only, no SSID attribute exists anywhere in
  the integration. Not achievable without a different data source.
- Redesigning the wake/idle backlight logic, PIR, or touch wiring.

## Anti-goals

- A screen so dense it's unreadable at a glance from rack distance.
- Any change that makes the display depend on HA being reachable to
  boot or to show the rack-air/PIR/touch basics — those stay local
  (direct GPIO/one-wire), only the *added* data depends on the HA API
  connection.

## Constraints

- The board already authenticates to HA over the existing encrypted
  `api:` connection (same key OTA now inherits) — pulling HA entity
  states uses that same connection via ESPHome's `homeassistant` sensor
  platform. No new secrets or wiring.
- LVGL screen is a single physical panel; multiple data groups need
  multiple pages/tabs, not one dense page.
- `sensor.*` entities update only as fast as their source polls (NAS
  and router sensors are typically 30–60s cadence in HA); the display
  doesn't need to poll faster than that.

## Current state

- `esphome/rack-display.yaml`: one LVGL page, rack-air temp label bound
  via `on_value` + `lvgl.label.update` (works, confirmed via logs and
  on-screen).
- HA entities confirmed to exist and usable today:
  - `weather.coppell` (Tempest): temperature, humidity, wind, pressure,
    condition.
  - Synology "boulevardier": `sensor.boulevardier_volume_1_volume_used`,
    `..._volume_2_volume_used`, `..._volume_1_average_disk_temp`,
    `..._volume_2_average_disk_temp`, `..._cpu_utilization_total`,
    `..._memory_usage_real`, plus per-drive temp/status, throughput,
    DSM update, security status (not all used — see below).
  - AsusWRT (host entry has a placeholder IP in config but is live per
    Barrett's confirmation): `sensor.192_0_2_1_devices_connected`,
    `..._download_speed`, `..._upload_speed`. (Entity IDs are
    IP-derived; if the integration's host ever gets corrected to the
    real LAN IP, these entity IDs will change and the YAML will need
    updating.)

## Approaches considered

1. **ESPHome `homeassistant` sensor platform** (pull entity states over
   the existing API connection). Zero new infra, a few lines of YAML
   per entity, read-only. **Picked.**
2. **MQTT**: would need an MQTT broker + HA's MQTT integration publishing
   these states, plus ESPHome MQTT config. More moving parts for no
   benefit when the API connection already exists and is encrypted.
3. **REST polling** (ESPHome `http_request` hitting HA's REST API
   directly): bypasses the native integration for no reason; `api`-based
   sensors are simpler and this is what ESPHome's own HA integration is
   for.

Picked #1.

## Design

### Pages (LVGL, swipeable/tabbed)

1. **Home** — rack-air temp (°F) and outside temp (°F, from
   `weather.coppell`) side by side, so hot-rack-vs-ambient is a glance
   comparison. This replaces the current single-temp home page.
2. **Weather** — fuller Tempest readout: condition, humidity, wind,
   pressure — plus current time.
3. **NAS** — Boulevardier: volume-used % (both volumes), average disk
   temp (both volumes), CPU utilization (total), memory usage %.
   DSM-update/security-status are left off as glance tiles (better
   suited to an alert/badge later, not in this pass).
4. **Network** — AsusWRT: total connected device count, download speed,
   upload speed.

Existing PIR/touch wake behavior applies across all pages — any touch
or motion wakes the backlight to whichever page is currently selected;
page navigation itself is via touch swipe between tabs (LVGL tabview).

### Data plumbing

- One `sensor: platform: homeassistant` entry per HA entity above,
  each with its own `entity_id:` and an internal id for use in LVGL
  `text:/format:/args:` bindings.
- Each gets an `on_value:` trigger calling the matching
  `lvgl.label.update`, following the same pattern already proven for
  the rack-air sensor (LVGL text bindings don't auto-refresh; this is
  the established workaround in this file).
- Existing `rack_temp` (DS18B20) sensor's `format:` changes from `%.1f°C`
  to `%.1f°F`, with the C→F conversion done via dallas_temp's
  unit_of_measurement option or a lambda — builder's call on which, both
  are standard ESPHome patterns.

### Left to the builder

- Exact LVGL tabview/page-indicator styling (dots, swipe vs. arrow
  buttons) — visual polish, Barrett hasn't specified a preference.
- Entity IDs should be treated as `!secret`-free but copied exactly from
  the current entity registry; if AsusWRT's host config entry ever gets
  fixed to a real IP, the entity IDs change and will need updating then
  (flagged as a known fragility, not solved now).
- Field order/spacing within each page.
