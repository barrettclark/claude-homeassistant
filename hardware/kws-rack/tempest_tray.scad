// Tempest hub tray: a 1U plate that bolts to the REAR legs of the KWS
// Rack v2 with a small tray cantilevered forward into the rack, so the hub
// no longer sits on the Beelink EQ14's lid.
//
// Placement: rear of U7, directly above the EQ14 (U6). The tray floor sits
// at the bottom of U7, about 3 mm above the EQ14's lid, and reaches forward
// over the back of the EQ14. The display's board (front of U7-8) is well
// clear: it only reaches ~30 mm behind the front rails.
//
// The plate has openings either side of the tray so it doesn't block the rear
// airflow, and low lips on the tray hold the hub without covering its
// side USB plug (the plug sits well above a 5 mm lip).
//
// Print plate-down on the bed; the tray rises vertically, no supports. PETG.
//
// Coordinates: x across the rack, y up, z = depth into the rack from the
// rear legs. The part is symmetric, so seen from the back or the front it's
// the same.

$fn = 48;

// --- rack (KWS Rack v2, rear legs) ---
rack_u          = 44.333;         // KWS legs: measured pitch per the 9U build sheet
panel_h         = rack_u - 0.8;
panel_w         = 254;
rail_opening    = 222.25;
// Rear hole spacing, center to center. Front holes are 236.5 (confirmed by
// the faceplates). The KWS sheet lists different front and rear numbers,
// so MEASURE THE REAR LEGS before printing and set this.
rear_hole_pitch = 236.5;
ear_hole_d      = 5.5;            // M5 clearance
ear_hole_slot   = 6;              // generous horizontal slot, +/- 3 mm
hole_y_in_u     = [6.35, 38.1];   // outer holes of the U

// --- plate ---
plate_t         = 4;
window_margin_x = 12;             // solid band left inside the ears
window_margin_y = 8;              // top and bottom beams

// --- Tempest hub (caliper-measured 2026-11-16). The antenna rotates up;
// above the tray is open space (rear U8). ---
hub_w           = 102;            // measured
hub_d           = 141;            // measured, front to back
hub_h           = 35;             // measured, antenna folded down
hub_clear       = 1.5;            // per side

// --- tray ---
floor_t         = 3;              // ~150 mm cantilever
lip_h           = 5;              // above the floor, all three sides
lip_t           = 2.4;
gusset_l        = 50;             // along the tray
gusset_h        = 25;             // up the plate
vent_slot_w     = 4;
vent_slot_pitch = 9;
vent_margin     = 15;

// ---------------------------------------------------------------------

bay_w           = hub_w + 2 * hub_clear;
bay_d           = hub_d + hub_clear;
outer_w         = bay_w + 2 * lip_t;
floor_y         = -panel_h / 2;   // floor underside = plate bottom edge

module ear_holes() {
    for (x = [-1, 1], hy = hole_y_in_u)
        translate([x * rear_hole_pitch / 2, -rack_u / 2 + hy, -1])
            hull() for (dx = [-ear_hole_slot / 2, ear_hole_slot / 2])
                translate([dx, 0, 0]) cylinder(d = ear_hole_d, h = plate_t + 2);
}

module plate() {
    win_w = rail_opening - 2 * window_margin_x;
    win_h = panel_h - 2 * window_margin_y;
    difference() {
        translate([-panel_w / 2, -panel_h / 2, 0])
            cube([panel_w, panel_h, plate_t]);
        ear_holes();
        // airflow / cable openings either side of the tray; the plate stays
        // solid behind the tray so the floor and gussets have something to
        // hang from
        side_w = (win_w - outer_w) / 2 - 2 * lip_t;
        for (s = [-1, 1])
            translate([s * (win_w / 2 - side_w / 2) - side_w / 2, -win_h / 2, -1])
                cube([side_w, win_h, plate_t + 2]);
    }
}

module tray() {
    z0 = plate_t - 0.01;
    difference() {
        union() {
            // floor
            translate([-outer_w / 2, floor_y, z0])
                cube([outer_w, floor_t, bay_d + lip_t]);
            // side lips
            for (s = [-1, 1])
                translate([s * (bay_w / 2 + lip_t / 2) - lip_t / 2, floor_y, z0])
                    cube([lip_t, floor_t + lip_h, bay_d + lip_t]);
            // far lip (toward the front of the rack)
            translate([-outer_w / 2, floor_y, z0 + bay_d])
                cube([outer_w, floor_t + lip_h, lip_t]);
            // gussets tying the floor to the plate, on the lips
            for (s = [-1, 1])
                translate([s * (bay_w / 2 + lip_t / 2) - lip_t / 2, floor_y, z0])
                    rotate([90, 0, 90])
                        linear_extrude(lip_t)
                            polygon([[0, 0], [gusset_h, 0], [0, gusset_l]]);
        }
        // floor vents, front-to-back
        n = floor((bay_w - 2 * vent_margin) / vent_slot_pitch);
        for (i = [0 : n - 1])
            translate([-(n - 1) * vent_slot_pitch / 2 + i * vent_slot_pitch - vent_slot_w / 2,
                       floor_y - 1, z0 + vent_margin])
                cube([vent_slot_w, floor_t + 2, bay_d - 2 * vent_margin]);
    }
}

union() { plate(); tray(); }

// Sanity checks
assert(floor_t + hub_h <= panel_h + 0.8, "hub taller than 1U");
assert(gusset_l < bay_d, "gussets longer than the tray");
assert(outer_w <= rail_opening - 2 * window_margin_x, "tray wider than the plate opening band");
assert(gusset_h <= panel_h - window_margin_y, "gusset taller than the plate");
