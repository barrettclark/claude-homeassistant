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
| HC-SR501 PIR (bare driver board) | 1 | On hand. **No silkscreen on this unit.** Green PCB, two orange trim potentiometers (sensitivity + delay), BISS0001-family chip. Ships with a yellow snap-on cap over its 3-pin header that looks like a cable mount but isn't one — it pulls straight off, leaving 3 plain 0.1" pins. Pin order, confirmed against a vendor reference photo of the same board family, **with the board oriented sensor/dome side up and the two trim pots along the bottom edge**: left-to-right **GND, OUT, VCC**. Verify this on the bench (continuity to a known ground, then a motion test) before trusting it, since no two clone boards are guaranteed identical |
| BOJACK DS18B20 probe module kit | 1 | 1 m stainless probe + "PlugableTerminal" adapter board with the 4.7 kΩ pull-up built in. One side is a 3-way screw terminal for the probe (labeled `DAT / VCC / GND` down the edge); the other side is a 3-pin breakout (same `DAT / VCC / GND` labels) that bridges on to the board |
| JST 1.25 mm pigtail | 1 | 4-pin, on hand from the kitchen project. Fits **P1, P2 (SPI), and P3 (UART1) only** — confirmed by hands-on fit test, 2026-11-18. Does not fit P4 |
| 4-pin male-male pigtail for P4 | 1 | **On hand**, confirmed to physically seat in P4. Has male pins on both ends, so it can't plug straight into the DS18B20 adapter's or PIR's male breakout pins — the far end gets cut off and re-terminated, see Section 3 |
| JST/Dupont crimp pin + housing kit | 1 | **On hand** (see IMG_0851). Carrier strip of small gold crimp pins plus assorted small black 2.54 mm housings. Used to re-terminate the cut end of the P4 pigtail so it can plug onto the DS18B20 adapter and PIR headers |
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

**Three boards are involved.** Keep them straight:

1. **The ESP32-8048S043C display board itself** — the big orange PCB.
   Has (at least) 4 small connectors along its bottom/right edge, each a
   different JST-style socket: **P1** (next to USB-C), **P2** (`SPI`),
   **P3** (`UART1`/`USB`), **P4** (unlabeled function, bottom-right
   corner). Only P1 and P4 matter for this build.
2. **The DS18B20 adapter board**, silkscreened `PlugableTerminal` — a
   small black board with a green 3-way screw terminal on one side
   (labeled `DAT`/`VCC`/`GND` down the edge) and a 3-pin breakout (same
   labels) on the other. The 1 m stainless probe's cable runs to the
   screw-terminal side; it has a long black jacket that can look like an
   antenna lead at a glance, but it isn't a separate device.
3. **The PIR driver board** — a small green PCB with **two orange trim
   potentiometers** and a BISS0001-family chip, **no silkscreen on this
   particular unit**. Ships with a yellow snap-on cap over its 3-pin
   header; that cap is not a cable mount, it just pulls off, leaving 3
   plain 0.1" pins.

### P1 vs. P4 — confirmed physically different connectors

**P1**, right edge beside the USB-C port, is a **4-pin UART0 socket**:
**GND, RXD, TXD, 5V** in that physical order (silkscreen-confirmed,
2026-11-18). The middle two pins are shared with the onboard CH340
USB-serial bridge used for flashing and the logger console — never land
anything there, even briefly. Only the outer two pins (GND, 5V) are used,
for the PIR.

**P4**, bottom-right corner, is `GND / 3.3V / IO17 / IO18` in that order
(silkscreen-confirmed). **P4 takes a different, smaller JST housing than
P1** — confirmed on the bench, 2026-11-18, by trying to seat the P1-style
1.25 mm pigtail in P4 and failing. Don't assume a cable that fits one
fits the other. No matching pigtail for P4 is on hand yet — see Parts and
Open Items.

### Wiring plan

7 wires leave the ESP32 board: 4 off P4 (every pin used) and 2 off P1 (pins 1
and 4 only — never touch P1 pins 2/3, the UART0 RXD/TXD shared with the
flashing CH340). They terminate at the PlugableTerminal breakout and the PIR
bare header.

```
                              ESP32-8048S043C board
                       ┌─────────────────────────────────┐
                       │                                  │
                       │  P1 (4-pin, next to USB-C)       │
                       │  pin1  pin2  pin3  pin4          │
                       │  GND   RXD   TXD   5V            │
                       │   │    (skip)(skip) │             │
                       │   │                 │             │
                       │  P4 (4-pin, bottom-right)        │
                       │  pin1  pin2  pin3  pin4          │
                       │  GND   3.3V  IO17   IO18          │
                       │   │     │     │      │            │
                       └───┼─────┼─────┼──────┼────────────┘
                           │     │     │      │
        ┌──────────────────┘     │     │      │
        │       ┌─────────────────┘     │      │
        │       │       ┌────────────────┘      │
        │       │       │       ┌────────────────┘
        │       │       │       │
   (P4 pin1)(P4 pin2)(P4 pin3)(P4 pin4)
     GND     3.3V    IO17    IO18
        │       │       │       │
        │       │       │       └──────────────► PlugableTerminal breakout, DAT
        │       └──────────────────────────────► PlugableTerminal breakout, VCC
        │               └──────────────────────► PIR bare header, OUT (middle pin)
        └───────────────────────────────────────► PlugableTerminal breakout, GND

   (P1 pin1)                                  (P1 pin4)
     GND                                        5V
        └──────────────► PIR bare header, GND     └──────────────► PIR bare header, VCC
          (pin farthest from the trim pots)          (pin closest to board edge)


 DS18B20 probe (1 m stainless, 3 wires) → PlugableTerminal screw terminal (already wired):
   Yellow → DAT    Red → VCC    Black → GND
```

| # | From | To | Notes |
|---|---|---|---|
| 1 | ESP32 **P4, pin 1 (GND)** | PlugableTerminal breakout, **GND** | |
| 2 | ESP32 **P4, pin 2 (3.3V)** | PlugableTerminal breakout, **VCC** | Never 5V — the pull-up would put 5V on IO18, and ESP32 pins are 3.3V only |
| 3 | ESP32 **P4, pin 3 (IO17)** | PIR bare header, **OUT** (middle pin) | Same pin as the kitchen firmware |
| 4 | ESP32 **P4, pin 4 (IO18)** | PlugableTerminal breakout, **DAT** | |
| 5 | ESP32 **P1, pin 1 (GND)** | PIR bare header, **GND** (pin farthest from trim pots) | Skip P1 pins 2/3 entirely |
| 6 | ESP32 **P1, pin 4 (5V)** | PIR bare header, **VCC** (pin closest to board edge) | HC-SR501 wants 5V; its OUT is still 3.3V-safe |
| — | DS18B20 probe, yellow/red/black | PlugableTerminal screw terminal, DAT/VCC/GND | Confirmed wired this way on the bench, 2026-11-18 |

GND is run as two separate wires (P4 pin 1 → adapter, P1 pin 1 → PIR) — don't
try to splice them together off-board; the ESP32 already ties them together
internally.

### Making the P4 end of the cable

The on-hand 4-pin male-male pigtail already seats in P4, but both ends are
male pins, so the far end can't plug into the DS18B20 adapter's or PIR's male
breakout pins directly. Re-terminate that end with the crimp kit (IMG_0851):

1. Cut the pigtail a few cm past the end that plugs into P4, leaving that
   plug intact. Strip ~3 mm off each of the 4 freed wire ends.
2. Cut one gold crimp pin off the carrier strip per wire, right at the joint
   — don't cut into the pin's barrel.
3. Lay the stripped wire in the pin's open barrel. With a proper SH/JST
   crimp tool, crimp per its instructions. Without one (most hobbyists don't
   own the tiny 1.0/1.25 mm crimper), tack it with a small dot of solder
   instead — reliable at this current level — then fold the pin's
   insulation tab over the wire's jacket by hand with needle-nose pliers for
   strain relief.
4. Push each finished pin into a small black housing: orient it so the
   pin's spring tang faces the housing's internal locking ramp, push
   straight in until it clicks.
5. Tug-test every pin after seating. If it pulls back out, the tang didn't
   engage — release it (push the tang down through the housing's top slot
   with a pick) and reseat it.
6. Check wire-to-cavity position against row 1–4 of the table above with a
   continuity meter before this housing goes anywhere near the DS18B20
   adapter or PIR.

### Verification before powering anything

- **PIR pin identity**: with no silkscreen on this unit, don't trust the
  vendor-photo pin order blind. Unpowered, multimeter in continuity mode:
  probe each of the 3 bare pins against a known ESP32 ground point (the
  USB-C shield, or a mounting-hole rim) to confirm **GND**. Then power the
  ESP32 over USB-C and check the remaining two for voltage — steady few
  volts is **VCC**, near-0V that you can toggle by waving a hand in front
  of the sensor (once VCC is actually connected) is **OUT**. Don't land a
  wire on a pin you haven't confirmed.
- **P1 pin 1 vs. pin 4**: confirm 5V is actually present at pin 1 with a
  multimeter while powered over USB-C, rather than trusting silkscreen
  left-to-right — sources disagree on which end is pin 1 for this board
  family.
- **Dupont pigtail wire-to-pin mapping**: check continuity from each JST
  pigtail's dupont end back to its pin position in the housing before
  landing it on the adapter or PIR — wire color isn't guaranteed to match
  pin order between pigtails.

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
- **P4 pigtail resolved, 2026-11-19**: a 4-pin male-male pigtail on hand
  fits P4. Its far end needs re-terminating with the crimp kit (see
  Section 3, "Making the P4 end of the cable") before it reaches the
  DS18B20 adapter and PIR — not yet done.
- **PIR pin identity (GND/OUT/VCC) is vendor-photo-sourced, not
  board-confirmed** — this unit has no silkscreen. Verify with a
  multimeter (continuity for GND, then voltage/motion-test for VCC/OUT)
  before the faceplate goes back together.
