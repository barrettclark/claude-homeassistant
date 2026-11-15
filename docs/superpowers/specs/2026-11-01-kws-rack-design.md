# KWS Rack — Office Homelab Rack Design

## Context

A 3D-printed 10-inch rack ([KWS Rack v2](https://makerworld.com/en/models/2139130),
planner at [kwslabs.com/racks](https://kwslabs.com/racks/)) to consolidate
the network/storage gear that currently sits loose on the office desk under
the shelf (shelf to be removed). The rack isn't Home Assistant hardware, but
it lives in this repo because its front display is the ESP32 board from the
kitchen dashboard project (`hardware/rack-display/`), and the build guide
sits alongside it at `hardware/kws-rack/ASSEMBLY.md`.

Location: office desk, right-hand end, away from the X1 Carbon's exhaust.
Open frame: no side or top plates (a deliberate choice, see Thermal).
In the KWS planner the plates still appear in the config; they're
optional parts and simply aren't printed or cut.

## What goes in, what doesn't

The constraint that decided everything: a 10" rack gives ~222 mm between
rails and well under 300 mm of usable depth.

| Device | Size (W×D×H mm) | Decision |
|---|---|---|
| Synology DS423+ | 166 × 223 × 199 | **In.** 4U, KWS Synology 4-bay module, bottom of rack (heaviest). |
| Beelink EQ14-DL | 126 × 126 × 39 | **In.** 1U, feet removed. |
| ESP32-8048S043C display | 123 × 74 board | **In.** 2U faceplate, top of rack. |
| Asus RT-BE7200 (RT-BE88U) | 300 × 188 × 61 + 4 antennas | **On top.** Too wide flat; antennas need open air. |
| Tempest WiFi hub | ≈100 wide × 30 tall | **In, on the EQ14's lid** behind the display. The top is full of router cables. Check RSSI in the Tempest app before and after. |
| Epson ET-4850 | 375 × 347 × 231 | **Out.** 150 mm wider than the rails. Stays on the desk. |
| Sunlu FilaDryer S2 | 265 × 118 × 274 | **Out.** Heat source next to HDDs; replaced by a FilaDC i10 cabinet. |

## Rack elevation (9U)

Frame: 6U base + 3U extension kit, heat-set inserts, standard joint plates
at the 6U joint (planner "mid braces" dropped: not in the published files), flat top connector instead of the handles (the handles rise ~97 mm
above the frame and a 300 mm router can't sit flat on them), no side
plates, 4 adhesive rubber feet. Per the KWS 9U build sheet
(`hardware/kws-rack/kws-9U-build-sheet.md`): frame 400.1 mm tall (496.9 mm
overall), footprint 288 × 260 mm, measured rail pitch 44.333 mm/U.

| U | Contents | Notes |
|---|---|---|
| top | RT-BE7200 | Front-aligned on a flat top; its ports and cables take the back of the top |
| 9–8 | Display faceplate (2U) | Display right, PIR left (front view); eye level from the desk |
| 7 | Beelink EQ14-DL (1U shelf) | Tempest hub (≈100 × 30 mm) rides on its lid, hidden behind the display; ~90 mm of height free above the EQ14 |
| 6 | Tupavco TP1713 PDU | 4 × NEMA 5-15, surge protected, rear outlets |
| 5 | Vented blank | Flat, so it can't collide if the NAS pokes above 4U |
| 4–1 | Synology DS423+ (4U module) | On the KWS heavy-duty shelf |

The NAS goes on the heavy-duty shelf at the bottom because that's what the
shelf is for: the KWS Synology module is built around it, and the weight
(~5 kg with drives) keeps a printed frame planted. That pushed the PDU up
from U1 to U6. U5 is a flat blank, not a device, because the DS423+ is
199 mm tall against a 4U (177 mm) module face and may reach into U5.

## Power

Four outlets, all used:

1. DS423+ power brick
2. RT-BE7200 power brick
3. EQ14 (internal PSU, plain AC cord)
4. 2-port USB charger → display (USB-C) + Tempest hub

Bricks hang on 8" Miady outlet savers so they don't block adjacent outlets,
and are zip-tied to the rear legs, not resting on the NAS. No spare outlet
remains; any addition means a second strip or a larger PDU. The existing
CyberPower 650 VA UPS sits on the floor and feeds the PDU from a
battery-backed outlet; DSM's UPS support handles clean NAS shutdown over USB,
and DSM's network UPS server can tell the EQ14 to shut down as well. Rack
load is roughly 70–100 W, well inside the UPS's rating.

PDU choice: two cheaper 8-outlet pigtail strips were considered and
rejected: neither listed surge protection or a UL/ETL mark.

## Thermal

Open sides: no fans. Both compute devices self-cool (DS423+ rear fans,
which the KWS module keeps aligned; EQ14 internal fan). The U5 vented
blank and U6 PDU put two units between the NAS and the EQ14. Top plate is
the solid "no fan" variant since the router sits on it. Rule if side
panels are ever added: switch to the KWS top plate with the 140 mm fan
opening and fit an exhaust fan.

## Display

Re-purposes the kitchen dashboard's ESP32-8048S043C as a rack display.
Differences from the kitchen case:

- Powered from USB-C on the PDU's USB charger; no AA pack, no MT3608, no
  electronics bay.
- Mounted glass-first behind a 2U 10" faceplate on 4 M2.5 standoffs
  (`hardware/rack-display/rack_faceplate.scad`).
- Display on the right so the board's USB-C (left edge, front view) exits
  toward open space; 32 mm reserved for the plug.
- HC-SR501 PIR beside the screen for wake/dim (IO17 on P4, same as the
  kitchen firmware). Keystones are supported by the file but off: nothing
  needs front access.
- Optional DS18B20 on IO18 for rack-air temperature. Low priority: the
  Synology integration already reports NAS temps.

Board measurements (calipers, 2026-11-01): PCB 123.15 × 73.9; hole pitch
116 × 67 (≈3.5 mm inset, not 6); hole Ø3.0 (M2.5); glass 105.47 × 67.2
(this is the glass outline: a 4.3" 5:3 panel's lit area is ≈93.6 × 56.2);
glass ~5.75 mm proud of the PCB; glass offset −0.2 x / −0.5 y.

## Open items

- **Ear-hole spacing.** Both faceplates assume EIA 10" spacing (236.5 mm
  center to center) and KWS's measured 44.333 mm/U vertical pitch. The
  KWS sheet's "front mount spacing 260 mm" probably describes the legs,
  not the hole pattern; measure across the first assembled front legs
  before printing device parts.
- **NAS height vs. U5.** Dry-fit the DS423+ on the heavy-duty shelf and see
  where its top lands.

- **Kitchen `params.scad` is stale.** `board_hole_inset` (6 → 3.5) and
  `standoff_pilot_d` (M3 2.5 → M2.5 2.1) are wrong, and `screen_active_*`
  is actually the glass outline. The rack faceplate uses its own measured
  values; the kitchen case still needs the fix.
- **`display_front_t` = 5.75 is "maybe."** First print is the test: foam
  tape if the glass rattles, −0.25 mm if the board bows.
- **PIR bore** (24 mm) still unverified against the actual HC-SR501.
- **DS423+ module fit:** the KWS Synology module lists DS923+/920+/918+/
  916+, not the 423+, which shares their chassis and rear-fan layout
  (a DS418play is reported as a perfect fit). Reviewers flag the NAS DC
  power plug fouling the module's rear panel; dry-fit before printing it.
- **Rack depth vs. NAS:** DS423+ is 223 mm deep plus rear cables. Check the
  KWS planner's stock depth; a 320 mm-deep connector remix exists if needed.
- **EQ14 shelf** (`hardware/kws-rack/eq14_shelf.scad`): 1U faceplate
  with an I/O window plus a cantilevered tray (side rails, rear stop,
  floor vents, gussets). Uses Beelink's published 126 × 126 × 39 mm
  without feet; check the slip fit (0.8 mm/side) on the first print.
- **Rack display firmware:** new ESPHome config (rack-specific pages: NAS,
  Tempest, network) not started.
