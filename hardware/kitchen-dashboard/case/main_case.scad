// Kitchen dashboard case: rear shell + front bezel.
// Two-part shell, joined with M3 self-tapping screws at 4 corner bosses.
// Board sits on 4 standoffs above the electronics bay (battery + MT3608).
// Print both parts; front face down for the bezel (screen cutout clean edge),
// rear shell open-face-down for a clean exterior back.

include <params.scad>

$fn = 64;

module rounded_rect(l, w, r) {
    hull() {
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (l / 2 - r), y * (w / 2 - r)])
                circle(r = r);
    }
}

module corner_boss_positions() {
    inset = corner_r + 4;
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (case_outer_l / 2 - inset), y * (case_outer_w / 2 - inset)])
            children();
}

module board_hole_positions() {
    for (x = [-1, 1], y = [-1, 1])
        translate([
            x * (board_l / 2 - board_hole_inset),
            board_center_y_offset + y * (board_w / 2 - board_hole_inset)
        ])
            children();
}

// ---------------- rear shell ----------------
// Every internal post (corner screw bosses, board standoffs, mount-
// accessory bosses) is built as its own solid-with-blind-hole and unioned
// onto the hollow tray AFTER the interior is cut — anything added before
// that cut sits inside the cavity footprint and gets hollowed out with it.
// Only the final through-holes (which must penetrate the assembled whole)
// are cut last.
module rear_shell() {
    shell_h = case_depth - wall_t; // front bezel supplies the last wall_t

    module base_box() {
        difference() {
            linear_extrude(height = shell_h)
                rounded_rect(case_outer_l, case_outer_w, corner_r);

            // hollow out the interior, leaving wall_t walls + floor
            translate([0, 0, wall_t])
                linear_extrude(height = shell_h)
                    rounded_rect(case_outer_l - 2 * wall_t, case_outer_w - 2 * wall_t, max(corner_r - wall_t, 1));

            // battery access hatch, cut through the back wall
            translate([-15, -10, -1])
                linear_extrude(height = wall_t + 2)
                    rounded_rect(hatch_l, hatch_w, 3);
        }
    }

    // corner posts: full-height columns, receive the front-bezel screws
    // from the top (blind pilot hole) and anchor to the floor at the bottom
    module corner_posts() {
        difference() {
            corner_boss_positions()
                cylinder(d = standoff_od + 2, h = shell_h);
            translate([0, 0, shell_h - 8])
                corner_boss_positions()
                    cylinder(d = standoff_pilot_d, h = 8 + 1);
        }
    }

    // board standoffs: full support columns from the case floor up to
    // just under the board. Sit near the board's corners, clear of where
    // the battery holder/boost module occupy the bay.
    // 0.1mm embedded into the floor so the union is a true volumetric
    // overlap, not just a coincident face (avoids non-fused touching solids)
    eps = 0.1;

    standoff_h = electronics_bay_depth + board_zone_depth - 2;
    module board_standoffs() {
        difference() {
            translate([0, 0, wall_t - eps])
                board_hole_positions()
                    cylinder(d = standoff_od, h = standoff_h + eps);
            translate([0, 0, wall_t + standoff_h - 6])
                board_hole_positions()
                    cylinder(d = standoff_pilot_d, h = 6 + 1);
        }
    }

    // mount-accessory bosses: inside face of the back wall, hold the M3
    // heat-set inserts the wall-hanger/stand accessory screws into
    module mount_bosses() {
        difference() {
            translate([0, mount_boss_y, wall_t - eps])
                for (x = [-1, 1])
                    translate([x * mount_boss_spacing / 2, 0, 0])
                        cylinder(d = mount_boss_od, h = 8 + eps);
            translate([0, mount_boss_y, wall_t])
                for (x = [-1, 1])
                    translate([x * mount_boss_spacing / 2, 0, 0])
                        cylinder(d = mount_boss_insert_d, h = 6);
        }
    }

    difference() {
        union() {
            base_box();
            corner_posts();
            board_standoffs();
            mount_bosses();
        }

        // mount-boss through-holes: screw shank enters from outside,
        // penetrating the back wall into the boss's insert hole above
        translate([0, mount_boss_y, -1])
            for (x = [-1, 1])
                translate([x * mount_boss_spacing / 2, 0, 0])
                    cylinder(d = mount_screw_clearance_d, h = wall_t + 2);
    }
}

// ---------------- battery hatch lid ----------------
module hatch_lid() {
    lid_l = hatch_l + 6;
    lid_w = hatch_w + 6;
    difference() {
        linear_extrude(height = 2)
            rounded_rect(lid_l, lid_w, 3);
        translate([lid_l / 2 - 6, 0, -1])
            cylinder(d = 2.5, h = 4);
        translate([-(lid_l / 2 - 6), 0, -1])
            cylinder(d = 2.5, h = 4);
    }
}

// ---------------- front bezel ----------------
module front_bezel() {
    difference() {
        linear_extrude(height = wall_t)
            rounded_rect(case_outer_l, case_outer_w, corner_r);

        // screen cutout (shifted to align with the offset board/standoffs)
        translate([0, board_center_y_offset, -1])
            linear_extrude(height = wall_t + 2)
                rounded_rect(screen_cutout_l, screen_cutout_w, 3);

        // PIR bore, centered in the top margin, above the screen
        translate([0, pir_bore_y, -1])
            cylinder(d = pir_bore_d, h = wall_t + 2);

        // corner screw clearance (screws pass through into rear shell bosses)
        translate([0, 0, -1])
            corner_boss_positions()
                cylinder(d = mount_screw_clearance_d, h = wall_t + 2);
    }
}

// ---------------- layout for printing ----------------
translate([-case_outer_l / 2 - 10, 0, 0]) rear_shell();
translate([case_outer_l / 2 + 10, 0, 0]) front_bezel();
translate([0, -case_outer_w / 2 - 20, 0]) hatch_lid();
