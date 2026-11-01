# Kitchen Dashboard — Firmware Sub-Project Design

## Context

Part of the larger kitchen wall-mounted dashboard project (see the sibling
power spec: `2026-09-11-kitchen-dashboard-power-design.md`). This doc
covers the firmware: platform choice, dashboard pages/content, the
proximity wake/sleep model, and how the device talks to Home Assistant.

A visual mockup of the three pages was reviewed and approved before
writing this spec — layout described below matches it.

## Hardware recap (from the power spec / board research)

- DIYmalls/Sunton ESP32-8048S043C — ESP32-S3-WROOM-1-N16R8, 800x480 RGB
  parallel display, GT911 capacitive touch.
- Backlight: PWM on GPIO2 (owned by the display driver).
- Touch (GT911): I2C, SCL GPIO20 / SDA GPIO19.
- RGB display bus: red `[45,48,47,21,14]`, green `[5,6,7,15,16,4]`,
  blue `[8,3,46,9,1]`, `de_pin:40`, `hsync_pin:39`, `vsync_pin:41`,
  `pclk_pin:42`.
- PIR signal in on **GPIO17** (the only fully free, non-boot-strapping pin
  besides GPIO18 — see power spec).

## Decision: ESPHome

Chosen over a custom Arduino/ESP-IDF + LVGL build because:
- This exact board has active community support in ESPHome (a device page
  exists on devices.esphome.io).
- Native Home Assistant integration comes for free via the ESPHome API —
  no hand-rolled HA REST/WebSocket client to build and maintain.
- ESPHome's `lvgl:` component handles the touch UI declaratively in YAML,
  consistent with how this whole repo already manages HA config as YAML.

## Dashboard pages

Three pages, swiped via touch gesture, with dot indicators. Last-viewed
page persists across sleep/wake (device does not reset to page 1 on
every wake).

### Page 1 — Home

Left column: a stack of light toggle tiles.
- **Fireplace** — `switch.fireplace`
- **Stained Glass Lamp** — `switch.tp_link_1` (entryway lamp; already has
  existing HA automations for its daily schedule — this panel adds manual
  override, it doesn't replace the schedule)
- **Christmas Lights** — a **new HA switch group helper** (not yet
  created) combining `switch.inside_christmas_lights`,
  `switch.front_yard_christmas_lights`, and
  `switch.back_patio_christmas_lights` into one entity. **Open item**:
  create this via Settings → Devices & Services → Helpers → Create Helper
  → Switch Group in the HA UI before the firmware can reference it — per
  this repo's own rule, entity/device creation happens manually in the UI,
  not through YAML push.
  - This tile is **conditionally visible**, shown only while
    `binary_sensor.christmas_season` is on, so the panel stays
    uncluttered outside the holidays.

Right column: 3 climate zone cards (current temp, +/- setpoint steppers,
mode chip) —
`climate.living_room_downstairs`,
`climate.living_room_kid_s_rooms`,
`climate.living_room_master_bedroom`.

### Page 2 — Weather (Tempest)

Hero: current temperature + "feels like", from the `weatherflow_cloud`
integration (station "Coppell"):
- `sensor.coppell_temperature`, `sensor.coppell_feels_like`

Stat grid below: `sensor.coppell_wind_speed` (+ `..._wind_direction` for
the compass label), `sensor.coppell_relative_humidity`,
`sensor.coppell_uv_index`, `sensor.coppell_precipitation_today`.

### Page 3 — Solar (Enphase Envoy)

Live production-vs-consumption flow:
- `sensor.envoy_202230068603_current_power_production`
- `sensor.envoy_202230068603_current_power_consumption`

Today's totals row:
- `sensor.envoy_202230068603_today_s_energy_production`
- `sensor.envoy_202230068603_today_s_energy_consumption`

## Wake/sleep model

- **Wake source**: PIR on GPIO17 (see power spec — light sleep, not deep
  sleep, so RAM/WiFi state survives and wake is near-instant rather than a
  multi-second reboot).
- **On wake**: resume whichever page was last shown, not always Home.
- **Auto-sleep**: return to light sleep after ~30-60s with no touch input
  and no PIR re-trigger.
- **Seasonal tile visibility** (Christmas Lights) is evaluated continuously
  via the `homeassistant` binary_sensor platform, independent of
  sleep/wake state, so the tile is correct whenever the screen wakes.

## Home Assistant integration mechanism

Two directions, two different ESPHome patterns:

- **Reading** (climate temps/modes, weather sensors, solar sensors, the
  seasonal binary sensor): ESPHome's `platform: homeassistant` sensors/
  binary_sensors/text_sensors pull entity state directly — no polling
  logic needed in this device's own code.
- **Writing** (toggle fireplace/lamp/Christmas lights, adjust a climate
  setpoint): ESPHome's `homeassistant.service:` action calls the real HA
  service (`switch.toggle`, `climate.set_temperature`) directly. The panel
  holds no state of its own — it's a thin client reflecting HA's actual
  state, so it can't drift out of sync with the rest of the house.
- Requires the ESPHome native **API** enabled with an encryption key,
  following this repo's existing `secrets.yaml` pattern for storing it.

## Repo placement

`esphome/kitchen-dashboard.yaml`, alongside a reference into this
project's existing `secrets.yaml` for the API encryption key and WiFi
credentials. Kept outside `config/` since this is compiled/flashed
firmware, not something synced via `make push`.

## Open items carried forward

- **Create the Christmas Lights switch group helper** in the HA UI before
  wiring up that tile (see Page 1 above).
- **Case spec** needs: touchscreen cutout matching the 800x480 panel,
  PIR bore on the face (angled toward the room for proximity detection),
  and the battery/electronics bay from the power spec.
- Validate actual light-sleep current draw once firmware is running,
  per the power spec's runtime target.
