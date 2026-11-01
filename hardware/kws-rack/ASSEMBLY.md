# KWS Rack — Assembly Guide

Build guide for the office homelab rack. Design rationale, U-map and open
items are in `docs/superpowers/specs/2026-11-01-kws-rack-design.md`. The
display faceplate source lives in `hardware/rack-display/`.

## Bill of materials

### Printed (PETG; the KWS designer warns PLA deforms in homelab heat)

| Part | Source | Notes |
|---|---|---|
| 6U base rack | [KWS Rack v2](https://makerworld.com/en/models/2139130), "6U Base Rack" profile | ~40 h, 10 plates. Print with walls > infill (Bambu "Strength") |
| 3U frame extension | same model, "3U Frame extension kit" | ~14 h |
| Synology 4-bay module (4U) | [MakerWorld 2254100](https://makerworld.com/models/2254100) | Skip its base if you already printed the KWS base |
| EQ14 1U shelf | `hardware/kws-rack/eq14_shelf.scad` | Face-down on the bed; tray prints vertically, no supports |
| Vented 1U blank | KWS page links a blank-panel generator | U6 |
| Display faceplate (2U) | `hardware/rack-display/rack_faceplate.scad` | Face-down on the bed |
| Side/top plates | **Not used**: the rack stays open | Skip them; if added later, add a fan |

### Frame hardware (9U, from the KWS hardware table)

| Item | Qty | Spec |
|---|---|---|
| Brass heat-set inserts | 108 + spares | M5, 8 mm long, 7 or 7.5 mm OD |
| Socket head screws (outer frame) | 32 | M6 × 8 |
| Socket head screws (inner frame) | 48 | M6 × 10 |
| Nyloc nuts | 80 | M6 |
| Rack-part screws | ~24 actually used | M5 × 10 (table says ~72 for a full rack) |
| Magnets (optional) | 79 | 10 × 5 mm round |

### Display

| Item | Qty | Notes |
|---|---|---|
| ESP32-8048S043C board | 1 | On hand |
| HC-SR501 PIR | 1 | On hand (5-pack) |
| M2.5 × 6 pan-head self-tapping screws | 4 | Board holes are Ø3.0: M3 won't fit |
| M2 screws, short | 2 | PIR to faceplate (28.5 mm spacing) |
| Short USB-C cable, right-angle preferred | 1 | Board → USB charger |
| Thin foam tape | — | Only if the glass rattles |
| DS18B20 + 4.7 kΩ resistor (optional) | 1 | IO18, rack-air temp |

### Power and cabling

| Item | Qty | Notes |
|---|---|---|
| Tupavco TP1713 10" PDU | 1 | 4 outlets, surge protected |
| Miady 8" outlet savers | 2–3 | Have a 10-pack |
| 2-port USB charger, ≥2.4 A/port | 1 | Display + Tempest hub |
| Short Cat6 patch cables | 2–3 | Router (top) → NAS, EQ14 |
| Velcro ties | — | Bricks to rear rails, cable runs |
| UPS, 600–850 VA line-interactive (optional) | 1 | Floor; USB to the DS423+ |

## 1. Print, in this order

1. **6U base rack** first. It's the longest print and the thing everything
   else is checked against.
2. **Display faceplate** next. It's the part most likely to need a second
   revision (see step 4), so get the first print in early.
3. **Synology module**, then the **EQ14 shelf**, **vented blank**, and
   **3U extension**.

Before the full faceplate, consider a quick test: print just the four
standoffs plus window area (crop in the slicer) to confirm hole alignment.

## 2. Build the frame

Per the KWS model page:

1. Press M6 nyloc nuts into the inner side of the frame parts (nylon facing
   away from the screw; push with a hex key). Epoxy the nuts inside the
   top handles: it makes later maintenance much easier once panels are on.
2. Heat-set the M5 inserts into the frame legs from the rack's inner side.
3. Snap in magnets (optional).
4. Assemble the 6U base with the connectors, then stack the 3U extension.

## 3. Pre-flight the gear (on the desk, before racking)

- Remove the EQ14's rubber feet.
- Confirm the DS423+ module's compatibility list covers the 423+.
- Check the frame's actual internal depth against the DS423+ (223 mm) plus
  ~40 mm for rear cable bend. If it's tight, the 320 mm-deep connector
  remix is the fix.

## 4. Display faceplate

1. Seat the board glass-first onto the 4 standoffs; drive the M2.5
   self-tappers from behind. Snug only: overtightening bows the PCB
   against the glass.
2. If the glass rattles behind the window, add foam tape. If the board
   bows, set `display_front_t` 0.25 lower and reprint.
3. Mount the PIR behind its bore (dome facing out) with the M2 screws.
4. Wire PIR → P4 (`GND`, `IO17`; 5 V from P1's 5 V pin, same as the
   kitchen wiring minus the boost converter). Optional DS18B20 → IO18.
5. Flash and test on the bench over USB-C before racking.

## 5. Rack it, bottom-up

| U | Install |
|---|---|
| 1 | PDU (outlets to the rear) |
| 5–2 | DS423+ in its module |
| 6 | Vented blank |
| 7 | EQ14 shelf |
| 9–8 | Display faceplate |
| top | Router + Tempest hub |

Faceplates take M5 × 10 into the frame inserts (4 per part).

## 6. Power and cabling

1. PDU outlets: NAS brick, router brick (on outlet savers), EQ14 cord,
   USB charger.
2. Zip-tie the bricks to the rear rails; nothing rests on the NAS.
3. USB charger → display USB-C and Tempest hub.
4. Patch router LAN → NAS and EQ14, down the back of the rack.
5. Optional: PDU into the UPS; UPS USB → DS423+, then enable DSM's UPS
   support (Control Panel → Hardware & Power → UPS).

## 7. Shake-down

- Watch DS423+ drive and system temps in DSM for the first few days
  (or via HA's Synology integration).
- Feel the EQ14's top after a sustained load. If U6's vent isn't enough
  separation, swap the blank for a fan panel.
- If side/top panels go on later, add an exhaust fan at the same time.
