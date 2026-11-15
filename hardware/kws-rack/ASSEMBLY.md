# KWS Rack — Assembly Guide

Build guide for the office homelab rack. Design rationale is in
`docs/superpowers/specs/2026-11-01-kws-rack-design.md`.

The **frame** follows the KWS planner's own build sheet, saved here as
`kws-9U-build-sheet.md` (parts/hardware as `kws-9U-parts-and-hardware.csv`),
generated from kwslabs.com/racks for 9U = 6U base + 3U extension, mid
braces at 6U (we dropped the braces; see below). This guide covers only where our build departs from it, plus
everything the planner doesn't know about: the devices.

## Departures from the KWS build sheet

| KWS sheet says | We do | Why |
|---|---|---|
| 2 × side plates (acrylic or printed) | **Skip.** Skip step 7 entirely | Open rack; side plates would trap NAS heat with no fan |
| 2 × top handle halves | **Flat top connector** instead | Handles rise ~97 mm above the frame (497 vs 400 mm); the 300 mm router can't sit flat on or between them |
| Top plate with 140 mm fan grill | **"Top plate no Fan"** profile, if the flat top still takes a plate | Solid surface under the router; no fan needed open-sided |
| Step 9, fan + grill | **Skip** | Same |
| Heavy-duty shelf | **Split version** (fits the X1C bed) | Single-piece is too big for the bed |
| Mid braces at the 6U joint | **Standard joint face and side plates** (plate 05, "Extension connectors") | The braces aren't in the published files; standard joints are how KWS racks are built and are ample at 9U |
| ~72 × M5 × 10 | **~30 is plenty**: buy a 50-pack | Only 6 front panels (4–6 screws each) |
| 79 magnets | Optional, skip or buy later | Convenience only |
| (nothing under the frame) | **4 adhesive rubber feet** under the bottom connectors | Grip on the desk, no scratches, damps drive vibration |

Planner config still lists smoked-acrylic side/top plates; ignore those
lines.

## Device parts (not in the KWS sheet)

| Part | Source | Notes |
|---|---|---|
| Synology 4-bay module | [MakerWorld 2254100](https://makerworld.com/models/2254100), designer's "Synology for KWS Rack" profile | Front panel (4U, 5 keystone slots), rear fan-aligned panel, stoppers. Its plate set includes the heavy-duty base: skip it, the KWS base kit already has one |
| Blank keystones | Any standard printable keystone blank, e.g. Printables 587874 "Keystone blank" | 5, to close the NAS front panel's slots. Test one first: snap fit varies |
| Display faceplate (2U) | `hardware/rack-display/rack_faceplate.scad` | Face-down on the bed |
| EQ14 1U shelf | `hardware/kws-rack/eq14_shelf.scad` | Face-down; tray prints vertically, no supports |
| Vented 1U blank | Blank-panel generator linked from the KWS page | U5 |

### Display hardware

| Item | Qty | Notes |
|---|---|---|
| ESP32-8048S043C board | 1 | On hand |
| HC-SR501 PIR | 1 | On hand (5-pack) |
| M2.5 × 6–8 machine screws | 4 | **On hand.** Board to faceplate; they cut their own thread in the 2.1 mm pilots. Drive by hand, stop at snug. Holes are Ø 3.0: M3 won't fit |
| M2 screws, short | 2 | PIR to faceplate (28.5 mm spacing) |
| 1 ft USB-A → right-angle USB-C cable | 1 | Board → USB charger. USB-A always supplies 5 V; a C-to-C cable from a USB-C charger may deliver nothing to this board |
| Thin foam tape | — | Only if the glass rattles |
| BOJACK DS18B20 probe module kit (optional) | 1 | Rack-air temp on IO18; pull-up resistor built into the adapter |

### Power and cabling

| Item | Qty | Notes |
|---|---|---|
| Tupavco TP1713 10" PDU | 1 | 4 outlets, surge protected; mount with M5 × 10 into the frame inserts |
| Miady 8" outlet savers | 2–3 | Have a 10-pack |
| Amazon Basics 24 W dual USB-A charger | 1 | 2.4 A per port; display + Tempest hub. USB-A on purpose (see the display cable). Confirm a UL mark |
| Short Cat6 patch cables | 2–3 | Router (top) → NAS, EQ14 |
| Velcro ties | — | Bricks to rear legs, cable runs |
| CyberPower 650 VA UPS | 1 | **On hand.** Floor; PDU into a battery-backed outlet; USB to the DS423+ |

### Frame extras

| Item | Qty | Notes |
|---|---|---|
| Adhesive rubber/silicone feet, ~20 mm Ø × 6–8 mm | 4 (8-pack) | Under the bottom connectors |
| Isopropyl alcohol | — | Clean PETG before sticking the feet |
| 5-minute epoxy | — | Nuts inside the top handles |
| Soldering iron with M5 insert tip | 1 | Heat-set inserts at ~230 °C |

## 1. Print, in this order

1. **6U base rack legs + bottom connectors**: the core of the frame.
2. **Display faceplate**: the part most likely to need a second revision,
   so get its first print in early.
3. **Heavy-duty shelf (split)**, then the **Synology module**.
4. **3U legs** (plate 07) + **extension connectors** (plate 05), **top connectors** + **flat top** (plates 03, 10),
   **solid top plate**.
5. **EQ14 shelf**, **vented blank**.

## 2. Check the rail geometry before printing faceplates

Our faceplates assume KWS's measured vertical pitch (44.333 mm/U, from the
build sheet) and the EIA 10" ear-hole spacing of **236.5 mm center to
center**. Once the first front leg pair is assembled with inserts, measure
the insert spacing across the two front legs. If it isn't ~236.5, change
`ear_hole_pitch` in both `.scad` files before printing the device parts.
(The sheet's "front mount spacing 260 mm" reads like a leg-to-leg
dimension, not the hole pattern, but the caliper settles it.)

## 3. Build the frame

Follow `kws-9U-build-sheet.md` steps 1–6 and 8, applying the departures
above. Heat-set inserts (step 2) go in from the leg's inner side, flush on
both faces, at about 230 °C: a proud insert stops a panel sitting flat. Epoxy the nuts inside the top connectors, as the sheet recommends for
the handles: once the rack is cabled you won't reach them again.

## 4. Rubber feet

With the frame built and before anything heavy goes in, turn it over and
stick one adhesive rubber foot under each corner of the bottom connectors
(clean the PETG with isopropyl alcohol first). Keep them inside the
footprint so they don't show. They grip the desk, protect it from the
PETG, and soak up a little of the drives' vibration.

## 5. Pre-flight the gear (on the desk, before racking)

- Remove the EQ14's rubber feet.
- The Synology module lists the DS923+, DS920+, DS918+ and DS916+, not
  the DS423+ by name. The 423+ uses the same 166 × 199 × 223 mm 4-bay
  chassis with the same two rear fans, and a reviewer reports a perfect fit
  with a DS418play, so it should fit; the dry fit confirms it.
- **NAS power cable vs. the module's rear panel.** Reviewers found the
  DC plug sticks out far enough to block the rear plate. The designer
  bends the cable sideways under a separator; one maker drilled a cable
  hole. Check this on the dry fit before printing the rear panel twice.
- **Stoppers (optional).** Two printed pieces that stop the NAS sliding
  sideways on the shelf. The top stopper slides in the shelf's rails and
  bolts from underneath; the side stopper needs inserts in the shelf's
  sides. The shelf drops in from the top and lifts back out, so either can
  be added any time. Start with the top stopper only.
- Depth: the frame is 260 mm deep; the DS423+ is 223 mm plus rear cables.
  Cables exit through the open back, so this should fit; dry-fit first.
- **Where does the NAS top land?** The DS423+ is 199 mm tall and a 4U
  module covers 177 mm. Dry-fit it on the shelf and note whether it pokes
  into U5. That's why U5 is a flat vented blank and the PDU sits at U6.

## 6. Display faceplate

Build and bench-test the display per `hardware/rack-display/ASSEMBLY.md`:
mounting, wiring (PIR on IO17, DS18B20 on IO18 at 3.3 V), and the
ESPHome config. Rack it only once it works on the bench.

## 7. Rack it, bottom-up

| U | Install |
|---|---|
| 4–1 | DS423+ in the Synology module, on the heavy-duty shelf |
| 5 | Vented blank (covers the NAS top, lets it breathe) |
| 6 | Tupavco PDU (outlets to the rear) |
| 7 | EQ14 shelf |
| 9–8 | Display faceplate |
| on 7 | Tempest hub on the EQ14's lid, behind the display faceplate: antenna on the left angled back, USB plug on the right. Velcro it down. Fit it before the display goes on |
| top | Router on the flat top, front-aligned |

Faceplates take M5 × 10 into the frame inserts (4 per part).

## 8. Power and cabling

1. PDU outlets: NAS brick, router brick (on outlet savers), EQ14 cord,
   USB charger.
2. Zip-tie the bricks and the USB charger to the rear legs; nothing rests
   on the NAS. The 1 ft cable runs from the charger up to the display.
3. USB charger → display USB-C and Tempest hub.
4. Patch router LAN → NAS and EQ14, down the back of the rack.
5. Leave at least 4 cm between the rack's back and the wall: the NAS DC
   plug, PDU cords and router cables all exit the open back.
6. Plug the PDU into one of the CyberPower's **battery-backed** outlets
   (not a surge-only one). Run its USB cable to a DS423+ rear USB port,
   then enable UPS support in DSM (Control Panel → Hardware & Power → UPS).
   Optionally turn on DSM's network UPS server so the EQ14 can shut down
   cleanly too (NUT client pointed at the NAS).

## 9. Shake-down

- Watch DS423+ drive and system temps in DSM for the first few days
  (or via HA's Synology integration).
- Feel the EQ14's top after a sustained load.
- If side plates ever go on, the top plate's 140 mm fan opening becomes
  the exhaust: switch to the fan-grill plate at the same time.
