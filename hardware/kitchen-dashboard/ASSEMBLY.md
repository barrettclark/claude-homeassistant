# Kitchen Dashboard — Assembly Guide

Build order for the full project. Cross-references the three specs in
`docs/superpowers/specs/`:
`2026-09-11-kitchen-dashboard-power-design.md`,
`2026-09-11-kitchen-dashboard-firmware-design.md`,
`2026-09-12-kitchen-dashboard-case-design.md`.

## Parts on hand

- DIYmalls/Sunton ESP32-8048S043C display board
- HC-SR501 PIR sensor (WWZMDiB 5-pack)
- 3x AA NiMH rechargeable, 2800mAh (8-pack purchased)
- 3x AA battery holder w/ switch (Goweewon 2-pack — one spare holder)
- MT3608 boost converter module (Ferwooh 5-pack)
- JST-1.25mm-to-Dupont pigtail cables (single/double/quad) + bare hookup wire
- Soldering iron, solder, multimeter (already on hand)
- Bambu X1-C printer, PETG filament recommended for the case

## 1. Print the case parts

From `hardware/kitchen-dashboard/case/`:
- `main_case.scad` → rear shell, front bezel, battery hatch lid (3 parts,
  laid out side by side in the file)
- `wall_hanger.scad` and/or `stand.scad` → whichever mount you land on

**Before printing**: measure the board's actual corner-mounting-hole
inset with calipers and compare to `board_hole_inset` (currently 6mm,
estimated from photos) in `params.scad` — adjust if it's off, since the
standoffs won't line up otherwise. Open the `.scad` files in OpenSCAD,
adjust, re-render (F6), export STL.

Recommended material: PETG (better heat/humidity tolerance for a kitchen
than PLA).

## 2. Prep and trim the MT3608 boost converter

**Do this before wiring anything else to it.**

1. Connect the 3x AA holder (loaded with charged cells) directly to the
   MT3608's input pads — nothing else connected yet.
2. Measure the MT3608's output with a multimeter.
3. Adjust the onboard trimpot until output reads **exactly 5.00V**.
4. Only after confirming 5.00V, proceed to wire it to anything else.
   Skipping this step risks feeding the ESP32 board or PIR more than 5V,
   which can damage them.

## 3. Wire the power system

Per the power spec's wiring diagram:

```
3x AA holder (+/-) ──> MT3608 IN
                        MT3608 5V OUT ──┬──> ESP32 board P1 header (5V pin)
                                         └──> PIR VCC
                        MT3608 GND ──┬──> ESP32 board GND (P1 or P4)
                                     └──> PIR GND
                        PIR OUT (digital) ────> ESP32 board P4 header, IO17 pin
```

- **P1** (board's right edge, next to the USB-C port): 5V + GND
- **P4** (board's bottom edge, labeled `GND / IO17 / IO18`): PIR signal
  wire goes to **IO17**, plus a GND tap
- Prefer soldering bare wire directly to these header pads for permanent
  connections (per the power spec) — reserve the JST pigtail cables for
  anything you might want to disconnect later.

## 4. Flash the firmware

`esphome/kitchen-dashboard.yaml` is written and passes `esphome config`
validation (schema-level — see note below). Before flashing:

1. Fill in real values in `esphome/secrets.yaml` (WiFi credentials, a
   freshly-generated API encryption key, an OTA password) — it's
   gitignored, currently holds only placeholders.
2. Create the Christmas Lights switch-group HA helper (below) and update
   the `entity_id: switch.christmas_lights_all` placeholders in the YAML
   (3 places — one `binary_sensor: platform: homeassistant` and 2
   `homeassistant.service` calls) to match whatever entity ID HA actually
   assigns the helper.
3. **Note on validation**: `esphome config` confirms the YAML is
   schema-valid, but does not compile the C++ lambdas (that needs the
   full ESP-IDF toolchain download). Run `esphome compile
   kitchen-dashboard.yaml` before flashing to catch anything that only
   surfaces at compile time.
4. **Before final assembly**, flash over USB-C and confirm: display
   renders all 3 pages, touch/swipe works, HA entities populate
   (climate, solar, weather, lights), and the PIR wakes the display from
   GPIO17.
5. On first boot, double check the display image isn't shifted/torn —
   the `ESP32-8048S050` model's timing values are used as a stand-in
   (pin mapping confirmed to match this board, but it's technically the
   5.0" sibling panel's model entry). Adjust `hsync_*`/`vsync_*`/
   `pclk_frequency` under `display:` if needed.

**HA-side prerequisite**: create the Christmas Lights switch group helper
— Settings → Devices & Services → Helpers → Create Helper → Switch Group
— combining `switch.inside_christmas_lights`,
`switch.front_yard_christmas_lights`, and
`switch.back_patio_christmas_lights`. Do this before wiring that tile's
service calls, since ESPHome will reference the resulting entity ID.

## 5. Assemble

1. Mount the board on the rear shell's 4 standoffs (self-tapping M3 screws
   into the printed pilot holes).
2. Route the power/PIR wiring from the board's P1/P4 headers back into
   the electronics bay.
3. Place the MT3608 module and the AA battery holder in the electronics
   bay — arrange around the 4 standoff posts (exact layout not fixed in
   the case spec; use the space as it fits, avoiding the posts).
4. Mount the PIR sensor behind the front bezel's PIR bore, facing outward
   (2mm mounting holes, 28.5mm spacing per the PIR's datasheet).
5. Screw the front bezel onto the rear shell (4 corner screws).
6. Test power-on before closing the battery hatch lid, in case anything
   needs adjustment.
7. Close the battery hatch (2 small screws).

## 6. Mount

- **Wall**: drive 2 screws at the spacing used in `wall_hanger.scad`
  (`wall_screw_spacing`, default 80mm), leave heads proud ~3mm, hang the
  case on the wall-hanger plate's keyholes.
- **Counter**: screw the `stand.scad` kickstand to the same 2 mount
  bosses on the case back. The tilt angle is a first-pass estimate —
  check it sits stable and adjust the leg if needed.

## 7. Battery maintenance

Swap the 3x AA cells when depleted (~3-5 day target, unvalidated until
real current draw is measured) — recharge externally in a standard AA
charger and rotate a second charged set in, per the power spec.
