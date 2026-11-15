# Rack Display — Assembly Guide

The kitchen dashboard's ESP32-8048S043C board, rebuilt as a 2U faceplate
for the office KWS rack (U8–9). Rack-wide context is in
`hardware/kws-rack/ASSEMBLY.md` and
`docs/superpowers/specs/2026-11-01-kws-rack-design.md`; the faceplate
source is `rack_faceplate.scad` in this folder.

What changes from the kitchen build: USB-C power from the rack's USB
charger replaces the AA pack and MT3608 boost converter, the board mounts
behind a rack faceplate instead of in a case, and a DS18B20 probe adds a
rack-air temperature reading.

## Parts

| Item | Qty | Notes |
|---|---|---|
| ESP32-8048S043C board | 1 | On hand (same board family as the kitchen build) |
| HC-SR501 PIR | 1 | On hand |
| BOJACK DS18B20 probe module kit | 1 | 1 m stainless probe + adapter board with the 4.7 kΩ pull-up built in; screw terminal for the probe, header pins for jumpers |
| JST 1.25 mm pigtails | 2 | One 4-pin for P4, one for P1 (on hand from the kitchen project) |
| M2.5 × 6–8 machine screws | 4 | **On hand.** Board to faceplate; they cut their own thread in the 2.1 mm pilots. Drive by hand, stop at snug. Holes are Ø 3.0: M3 won't fit |
| M2 × 6 screws + nuts | 2 | PIR to faceplate, 28.5 mm spacing |
| 1 ft USB-A → right-angle USB-C cable | 1 | To the rack's USB-A charger. USB-A always supplies 5 V; a USB-C-to-C cable may deliver nothing to this board |
| Thin foam tape | — | Only if the glass rattles |
| Zip ties | 2–3 | Probe cable along a rear leg |

## 1. Print the faceplate

`rack_faceplate.stl`, PETG, face down on the bed. Board geometry was
caliper-measured on 2026-11-01 and is kept as rack-local values in the
`.scad` (hole pitch 116 × 67, glass 105.47 × 67.2, glass 5.75 mm proud of
the PCB). Display sits on the right, PIR on the left, seen from the front.

## 2. Mount the board

1. Seat the board glass-first onto the 4 standoffs and drive the M2.5
   machine screws from behind (they cut their own thread). Snug only: overtightening bows the PCB
   against the glass.
2. If the glass rattles behind the window, add foam tape around its edge.
   If the board bows, lower `display_front_t` by 0.25 and reprint.
3. Mount the PIR behind its bore, dome facing out, with the M2 screws.

## 3. Wire it

Two headers on the back of the board, seen from behind: **P1** on the
right edge beside the USB-C port, and **P4** on the bottom edge near the
right corner, labeled `GND / 3.3V / IO17 / IO18`.

| From | To | Notes |
|---|---|---|
| Probe red | Adapter **VCC** terminal | Screw terminal |
| Probe black | Adapter **GND** terminal | Screw terminal |
| Probe yellow | Adapter **DAT** terminal | Screw terminal |
| Adapter VCC | **P4 3.3V** | Never 5 V: the pull-up would put 5 V on IO18, and ESP32 pins are 3.3 V only |
| Adapter GND | **P4 GND** | |
| Adapter DAT | **P4 IO18** | |
| PIR OUT | **P4 IO17** | Same pin as the kitchen firmware |
| PIR VCC | **P1 5V** | The HC-SR501 wants 5 V; its output is still 3.3 V-safe |
| PIR GND | **P1 GND** | Taking PIR power from P1 means nothing on P4 needs splicing |

No battery pack, no MT3608: power comes in on the USB-C port.

## 4. Firmware

There's no rack config yet. Start `esphome/rack-display.yaml` from
`esphome/kitchen-dashboard.yaml` and keep the hardware blocks unchanged:
`esp32`/`psram`, the `logger` UART0 override, `i2c` on GPIO19/20, the
`mipi_rgb` display, `gt911` touch, the backlight on GPIO2, the PIR
`binary_sensor` on GPIO17 and the wake/idle scripts. Then:

- Rename the device and secrets: `rack_display_api_key`,
  `rack_display_ota_password`.
- Drop the kitchen pages and their Home Assistant entities (Christmas
  lights, fireplace, lamp, climate/solar tiles); rack pages are a
  separate piece of work.
- Add the temperature probe:

```yaml
esphome:
  name: rack-display
  friendly_name: Home Office Rack   # entity names are prefixed with this

one_wire:
  - platform: gpio
    pin: GPIO18

sensor:
  - platform: dallas_temp
    name: "Temperature"             # → sensor.home_office_rack_temperature
    update_interval: 60s
```

ESPHome prefixes every entity with the device's `friendly_name`, so
"Home Office Rack" + "Temperature" yields
`sensor.home_office_rack_temperature`, and the PIR named "Motion" yields
`binary_sensor.home_office_rack_motion`. Both follow the repo's
`location_room_device_sensor` convention.

As with the kitchen build: `esphome config` validates the schema only, so
run `esphome compile rack-display.yaml` before flashing.

## 5. Bench test, then rack it

1. Flash over USB-C and confirm: the display renders, touch works, the PIR
   wakes the backlight, and the temperature shows up in Home Assistant at
   roughly room temperature.
2. Install the faceplate at U8–9 (M5 × 10 into the rack inserts), after
   the Tempest hub is in place on the EQ14's lid.
3. Run the probe cable down a rear leg and zip-tie the tip level with the
   top of the NAS, just behind it, hanging in free air. That's the
   warmest air in the rack.
4. Plug the USB-A end into the rack's USB charger.

## Open items

- `display_front_t` = 5.75 mm is a "maybe" measurement; the first print
  settles it.
- PIR bore (24 mm) not yet checked against the actual HC-SR501 dome.
- Rack pages for the display (NAS, network, Tempest, rack temperature)
  aren't designed yet.
