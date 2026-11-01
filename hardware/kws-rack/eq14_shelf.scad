// Beelink EQ14 1U shelf for a 10-inch KWS Rack v2.
//
// A 1U faceplate with a window onto the EQ14's front I/O (power button,
// USB-A, USB-C, audio), and a cantilevered tray behind it: side rails to
// locate the box, a rear stop, floor vents, and gussets tying the tray to
// the faceplate. The EQ14 slides in from the back until its face meets
// the plate. Remove its rubber feet first.
//
// Print face-down (faceplate on the bed); the tray rises vertically and
// needs no supports. PETG.
//
// Front-view coordinates: x right, y up, z = depth into the rack.

$fn = 48;

// --- rack standard (EIA-310 10-inch), matches rack_faceplate.scad ---
rack_u          = 44.45;
panel_h         = rack_u - 0.8;   // 43.65
panel_w         = 254;
rail_opening    = 222.25;
ear_hole_pitch  = 236.5;
ear_hole_d      = 5.5;            // M5 clearance
ear_hole_slot   = 2;
hole_y_in_u     = [6.35, 38.1];   // outer holes of the U (0.25", 1.5")

// --- plate ---
plate_t         = 4;

// --- EQ14 (feet removed; manufacturer: 126 x 126 x 39 without feet) ---
dev_w           = 126;
dev_d           = 126;
dev_h           = 39;
dev_clear       = 0.8;            // per side, slip fit

// --- tray ---
floor_t         = 2.4;
rail_h          = 10;             // side rails locate the box
rail_t          = 2.4;
stop_h          = 12;             // rear stop
stop_t          = 2.4;
gusset_l        = 40;             // along the tray
gusset_h        = 30;             // up the faceplate
vent_slot_w     = 4;
vent_slot_pitch = 8;
vent_margin     = 18;

// --- front window onto the I/O ---
// Inset from the box edges so the plate overlaps the EQ14's rounded face
// and holds it; ports sit mid-height on the front.
window_inset_x  = 4;
window_inset_y  = 3;

// ---------------------------------------------------------------------

bay_w           = dev_w + 2 * dev_clear;
bay_d           = dev_d + dev_clear;
floor_y         = -panel_h / 2;                  // tray floor underside
dev_bottom_y    = floor_y + floor_t;
dev_center_y    = dev_bottom_y + dev_h / 2;
window_w        = dev_w - 2 * window_inset_x;
window_h        = dev_h - 2 * window_inset_y;

module ear_holes() {
    for (x = [-1, 1], hy = hole_y_in_u)
        translate([x * ear_hole_pitch / 2, -rack_u / 2 + hy, -1])
            hull() for (dx = [-ear_hole_slot / 2, ear_hole_slot / 2])
                translate([dx, 0, 0]) cylinder(d = ear_hole_d, h = plate_t + 2);
}

module faceplate() {
    difference() {
        translate([-panel_w / 2, -panel_h / 2, 0])
            cube([panel_w, panel_h, plate_t]);
        ear_holes();
        // I/O window with a chamfered front edge
        translate([0, dev_center_y, 0])
            hull() {
                translate([-window_w / 2, -window_h / 2, -0.01])
                    cube([window_w, window_h, plate_t + 0.02]);
                translate([-window_w / 2 - 1, -window_h / 2 - 1, -0.01])
                    cube([window_w + 2, window_h + 2, 0.01]);
            }
    }
}

module tray() {
    z0 = plate_t - 0.01;
    outer_w = bay_w + 2 * rail_t;
    difference() {
        union() {
            // floor
            translate([-outer_w / 2, floor_y, z0])
                cube([outer_w, floor_t, bay_d + stop_t]);
            // side rails
            for (s = [-1, 1])
                translate([s * (bay_w / 2 + rail_t / 2) - rail_t / 2, floor_y, z0])
                    cube([rail_t, floor_t + rail_h, bay_d + stop_t]);
            // rear stop
            translate([-outer_w / 2, floor_y, z0 + bay_d])
                cube([outer_w, floor_t + stop_h, stop_t]);
            // gussets: triangles in the y-z plane, outboard of the rails
            for (s = [-1, 1])
                translate([s * (outer_w / 2 + rail_t / 2) - rail_t / 2, floor_y, z0])
                    rotate([90, 0, 90])
                        linear_extrude(rail_t)
                            polygon([[0, 0], [gusset_h, 0], [0, gusset_l]]);
        }
        // floor vents: slots front-to-back, clear of rails and ends
        n = floor((bay_w - 2 * vent_margin) / vent_slot_pitch);
        for (i = [0 : n - 1])
            translate([-(n - 1) * vent_slot_pitch / 2 + i * vent_slot_pitch - vent_slot_w / 2,
                       floor_y - 1, z0 + vent_margin])
                cube([vent_slot_w, floor_t + 2, bay_d - 2 * vent_margin]);
    }
}

// Front view -> model space (see rack_faceplate.scad)
mirror([1, 0, 0]) union() { faceplate(); tray(); }

// Sanity checks
assert(dev_bottom_y + dev_h <= panel_h / 2, "EQ14 taller than the 1U opening");
assert(bay_w + 2 * rail_t + 2 * rail_t <= rail_opening, "tray + gussets wider than the rails");
