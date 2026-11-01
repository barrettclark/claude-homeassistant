// Rack display: 2U 10-inch faceplate for the ESP32-8048S043C board,
// sized for the KWS Rack v2 (standard 10" rail spacing, M5 screws).
//
// Seen from the front: display on the RIGHT, PIR (and optional keystones)
// on the LEFT. The board's USB-C port sits on its left edge (seen from the
// front), so putting the display on the right sends the cable toward open
// space instead of into the rail.
//
// Powered over USB-C, so there is no battery pack, boost converter or
// electronics bay as in the kitchen case. The board mounts from behind on
// 4 standoffs, with its glass pressed against the back of the plate.
//
// Coordinates below are FRONT-VIEW (x to the right as you face the rack,
// y up). The final mirror() converts them to model space, so the STL
// prints face-down with the front face on the bed.
//
// Board measurements (calipers, 2026-11-01) are kept as rack-local values
// below. params.scad's board_hole_inset / standoff_pilot_d are still the
// old estimates; once those are corrected there, these can fold back in.

include <../kitchen-dashboard/case/params.scad>   // pir_bore_d

$fn = 64;

// --- rack standard (EIA-310 10-inch) ---
rack_u          = 44.45;
panel_u         = 2;
panel_w         = 254;            // 10" full face incl. ears
panel_h         = panel_u * rack_u - 0.8;  // 88.1, standard panel clearance
rail_opening    = 222.25;         // usable width between rails
ear_hole_pitch  = 236.5;          // center-to-center, left/right holes
ear_hole_d      = 5.5;            // M5 clearance
ear_hole_slot   = 2;              // horizontal slotting for print/rail tolerance
// Per-U hole heights from the bottom of each U (0.25", 0.875", 1.5")
hole_y_in_u     = [6.35, 22.225, 38.1];
use_all_holes   = false;          // false = top + bottom holes only (4 screws)

// --- plate ---
plate_t         = 4;              // front plate thickness
rib_depth       = 8;              // rear stiffening ribs, top and bottom
rib_t           = 2.4;

// --- board, measured ---
rk_board_l      = 123.15;
rk_board_w      = 73.9;
rk_hole_pitch_x = 116;            // mounting holes, center to center
rk_hole_pitch_y = 67;
rk_hole_d       = 3.0;            // fits M2.5, not M3
rk_pilot_d      = 2.1;            // M2.5 self-tapping into PETG
// Glass outline (105.47 x 67.2). A 4.3" 5:3 panel's lit area is about
// 93.6 x 56.2, so this is the glass, not the pixels.
glass_l         = 105.47;
glass_w         = 67.2;
// Glass position on the PCB, front view. Measured gaps: left 9, right 9.4,
// top 4, bottom 3 (top/bottom approximate). Offset = (left - right)/2 and
// (bottom - top)/2 from the board center.
screen_offset_x = (9 - 9.4) / 2;  // -0.2
screen_offset_y = (3 - 4) / 2;    // -0.5
// PCB front surface to glass face. Measured ~5.75 ("maybe"): if the glass
// rattles, add foam tape; if the board bows, shave 0.25 off here.
display_front_t = 5.75;

// --- display placement ---
display_margin  = 10;             // gap from right rail to board edge
board_center_x  = rail_opening / 2 - display_margin - rk_board_l / 2;
glass_lip       = 1.0;            // plate overlaps the glass edge by this much
window_l        = glass_l - 2 * glass_lip;
window_w        = glass_w - 2 * glass_lip;
front_standoff_od = 5;
// USB-C plug + overmold sticking out of the board's left edge
usb_clearance   = 32;

// --- keystones (0 = clean panel) ---
ks_cols         = 0;              // 0 with the PIR; up to 2 without it
ks_rows         = 2;
ks_pitch_x      = 22;
ks_pitch_y      = 30;
// Standard snap-in keystone opening. Test-print one before the full plate:
// jack brands vary by a few tenths.
ks_cut_w        = 14.9;
ks_cut_h        = 16.3;
ks_snap_t       = 2.0;            // plate thickness the latch clips over
ks_pocket_w     = 19;             // rear pocket to thin the plate around each jack
ks_pocket_h     = 23;

// --- PIR (HC-SR501) left of the screen. With keystones it takes the
// outermost column; without them it centers in the space ---
pir_enable      = true;

// ---------------------------------------------------------------------

board_left_x    = board_center_x - rk_board_l / 2;
zone_left       = -rail_opening / 2 + 4;
zone_right      = board_left_x - usb_clearance;
zone_center     = (zone_left + zone_right) / 2;

module ear_holes() {
    for (x = [-1, 1])
        for (u = [0 : panel_u - 1])
            for (i = [0 : len(hole_y_in_u) - 1]) {
                y = -panel_u * rack_u / 2 + u * rack_u + hole_y_in_u[i];
                is_outer = (u == 0 && i == 0) || (u == panel_u - 1 && i == len(hole_y_in_u) - 1);
                if (use_all_holes || is_outer)
                    translate([x * ear_hole_pitch / 2, y, -1])
                        hull() for (dx = [-ear_hole_slot / 2, ear_hole_slot / 2])
                            translate([dx, 0, 0])
                                cylinder(d = ear_hole_d, h = plate_t + 2);
            }
}

module ks_positions(cols) {
    total_w = (cols - 1) * ks_pitch_x;
    for (c = [0 : cols - 1], r = [0 : ks_rows - 1])
        translate([zone_center - total_w / 2 + c * ks_pitch_x + (pir_enable ? ks_pitch_x / 2 : 0),
                   (r - (ks_rows - 1) / 2) * ks_pitch_y, 0])
            children();
}

// Holes are referenced to the board center; the glass offset doesn't move them.
module board_hole_xy() {
    for (x = [-1, 1], y = [-1, 1])
        translate([board_center_x + x * rk_hole_pitch_x / 2, y * rk_hole_pitch_y / 2])
            children();
}

module faceplate() {
    ks_cols_eff = pir_enable ? max(ks_cols - 1, 0) : ks_cols;
    pir_x = ks_cols_eff == 0 ? zone_center
                             : zone_center - (ks_cols - 1) * ks_pitch_x / 2;

    difference() {
        union() {
            // front plate
            translate([-panel_w / 2, -panel_h / 2, 0])
                cube([panel_w, panel_h, plate_t]);

            // rear ribs, kept inside the rail opening so the ears sit flat
            for (y = [-1, 1])
                translate([-rail_opening / 2 + 2,
                           y * (panel_h / 2 - rib_t / 2) - rib_t / 2,
                           plate_t - 0.01])
                    cube([rail_opening - 4, rib_t, rib_depth]);

            // board standoffs: rise from the plate's back face; the board
            // hangs on them glass-first, M2.5 self-tappers from behind
            translate([0, 0, plate_t - 0.01])
                board_hole_xy()
                    cylinder(d = front_standoff_od, h = display_front_t + 0.01);
        }

        ear_holes();

        // screen window: through the plate only (never into the standoffs),
        // with a 45° chamfer on the front edge so the bezel doesn't shadow
        // the outer pixels
        translate([board_center_x + screen_offset_x, screen_offset_y, 0])
            hull() {
                translate([-window_l / 2, -window_w / 2, -0.01])
                    cube([window_l, window_w, plate_t + 0.02]);
                translate([-window_l / 2 - 1.2, -window_w / 2 - 1.2, -0.01])
                    cube([window_l + 2.4, window_w + 2.4, 0.01]);
            }

        // standoff pilot holes
        translate([0, 0, plate_t + display_front_t - 6])
            board_hole_xy()
                cylinder(d = rk_pilot_d, h = 7);

        // keystones: through-cut plus a rear pocket leaving ks_snap_t of plate
        if (ks_cols_eff > 0) ks_positions(ks_cols_eff) {
            translate([-ks_cut_w / 2, -ks_cut_h / 2, -1])
                cube([ks_cut_w, ks_cut_h, plate_t + 2]);
            translate([-ks_pocket_w / 2, -ks_pocket_h / 2, ks_snap_t])
                cube([ks_pocket_w, ks_pocket_h, plate_t]);
        }

        // PIR bore + mounting holes (HC-SR501, 28.5 mm spacing)
        if (pir_enable) {
            translate([pir_x, 0, -1]) cylinder(d = pir_bore_d, h = plate_t + 2);
            for (y = [-1, 1])
                translate([pir_x, y * 28.5 / 2, -1]) cylinder(d = 2.2, h = plate_t + 2);
        }
    }
}

// Front view -> model space: viewed from the front (-z side), +x would
// otherwise appear on the left.
mirror([1, 0, 0]) faceplate();

// Sanity checks: fail loudly instead of printing a plate that doesn't fit.
assert(rk_board_w <= panel_h - 2 * rib_t, "board taller than the 2U plate");
assert(rk_hole_pitch_x / 2 - front_standoff_od / 2 > glass_l / 2 + abs(screen_offset_x),
       "standoffs collide with the glass edge");
assert(zone_right - zone_left >= (pir_enable ? 32 : 0) + max(ks_cols - (pir_enable ? 1 : 0), 0) * ks_pitch_x,
       "PIR/keystones don't fit beside the board; reduce ks_cols or usb_clearance");
