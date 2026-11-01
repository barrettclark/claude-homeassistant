# Kitchen Dashboard — Case Sub-Project Design

## Context

Third and final sub-project for the kitchen wall/counter dashboard, after
the power spec (`2026-09-11-kitchen-dashboard-power-design.md`) and
firmware spec (`2026-09-11-kitchen-dashboard-firmware-design.md`). Covers
the physical enclosure: board mounting, battery/electronics bay, PIR
placement, and the mounting method.

Parametric OpenSCAD source lives at
`hardware/kitchen-dashboard/case/` — `params.scad` (shared dimensions),
`main_case.scad` (rear shell + front bezel + battery hatch lid),
`wall_hanger.scad` and `stand.scad` (interchangeable mount accessories).
All three render clean, manifold geometry (verified with the OpenSCAD
CLI).

## Board measurements (physically measured, 2026-09-12)

- Overall board: 123.23mm (L) x 74mm (W) x 2.5mm (bare PCB thickness)
- Active screen area: 105.55mm x 67.29mm
- Total front-to-back stack depth (glass + PCB + tallest connector):
  8.5mm

## Pin header locations (from board photos)

Confirmed by inspecting the physical board, not just documentation:
- **Bottom edge** (left to right): RST/BOOT buttons, an unused touch-
  overlay FPC connector, the microSD slot, then three 4-pin JST 1.25mm
  headers — **P2** (SPI/microSD, unused), **P3** (touch I2C, unused,
  already wired internally), **P4** (`GND / IO17 / IO18` — **this is
  where the PIR signal and a ground tap connect**).
- **Right edge**: USB-C port, and **P1** right beside it (power pins —
  **this is where the boosted 5V from the power spec feeds in**).

This shapes the internal wiring channel: both connection points are on
the board's bottom-right region, so electronics-bay wiring routes from
there rather than needing access to the full board perimeter.

## Case architecture

Two-part shell (rear tray + front bezel), joined by 4 corner screws,
plus a separate small battery-hatch lid:

- **Rear shell**: outer tray with an electronics bay at the back
  (`electronics_bay_depth` = 20mm, sized for the MT3608 boost module +
  AA holder + wiring from the power spec) and 4 board standoffs rising
  from the floor to hold the board just under the front bezel. A battery
  access hatch is cut through the back wall, sized for the 3x AA holder,
  closed by a small separately-printed lid (2 screws).
- **Front bezel**: a thin cap with the screen cutout (sized to the
  active area + 1mm overlap onto the board's own black bezel, hiding
  print-edge tolerance without covering pixels) and the PIR bore.
- **Case footprint**: 141.23mm x 113mm outer, asymmetric top margin
  (30mm vs. 9mm on the other three sides) specifically to give the PIR
  bore room above the screen without overlapping it — the board/screen
  assembly sits shifted down within the taller case to make that room.
- **Case depth**: ~37.9mm (wall + board zone + electronics bay + wall) —
  slimmer than it sounds since most of that is the battery/boost bay
  behind the board, not visible depth added to the screen area.

## Mount: modular, interchangeable accessories

Rather than committing to wall-mount or countertop-stand, the case back
carries 2 M3 heat-set insert bosses (spacing set by `mount_boss_spacing`
in `params.scad`) that either accessory screws into:

- **`wall_hanger.scad`**: a plate with 2 keyhole slots, hangs directly on
  2 wall screws.
- **`stand.scad`**: a wedge/kickstand, tilts the case back ~18° for
  countertop viewing. The tilt is a first-pass approximation (a wedge
  hulled between the mounting point and a flat foot) rather than a
  precisely-derived angle — tune leg length/angle after a test print if
  the balance feels off.

Print whichever is needed later; neither commits the case design itself.

## Open items / verify before final print

- **Board mounting hole inset** (`board_hole_inset` = 6mm in
  `params.scad`) is an estimate from photos, not a direct measurement.
  Measure the actual corner-hole-to-edge distance before printing the
  first standoff test piece.
- **PIR bore diameter** (24mm) is sized from the HC-SR501's published
  dome/lens dimensions — confirm against the actual WWZMDiB unit once
  it's in hand, since dedicated-case variants can differ slightly.
- **Electronics bay layout**: the AA holder, MT3608 module, and wiring
  need to be arranged inside the bay avoiding the 4 board standoff posts
  — not yet laid out in detail; do this at assembly time or add fixed
  mounting features once the exact battery holder/module footprints are
  in hand.
- **Material**: recommend **PETG** over PLA for this part given kitchen
  heat/humidity exposure (matches the "presentable but functional"
  requirement from earlier in this project) — printer/filament already
  on hand (Bambu X1-C, PETG available).
- **Stand tilt/foot length** is a first-pass approximation — verify
  balance with a test print if you end up using the stand instead of
  the wall mount.
