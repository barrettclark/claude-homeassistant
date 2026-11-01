// Countertop kickstand accessory: screws to the case's 2 mount bosses
// (see params.scad), props the panel back ~18deg for a comfortable
// counter-viewing angle.
//
// Local axes: X = width (matches the case's horizontal), Y = vertical
// (down is -Y), Z = depth (away from the case is -Z). The mount plate's
// outward face (screw heads, away from the case) is at Z=0.

include <params.scad>

$fn = 48;

tilt_deg = 18;
mount_plate_l = mount_boss_spacing + 30;
mount_plate_w = 34;
mount_plate_t = 4;
leg_depth = 70;     // how far the foot extends behind the case
foot_w = mount_plate_l;
foot_t = 4;

module rounded_rect(l, w, r) {
    hull() {
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (l / 2 - r), y * (w / 2 - r)])
                circle(r = r);
    }
}

// mounting plate — flush against the case back, screws into the 2 bosses.
// Sits with its outward (screw-head) face at Z=0, case-facing side at
// Z=mount_plate_t.
module mount_plate() {
    difference() {
        linear_extrude(height = mount_plate_t)
            rounded_rect(mount_plate_l, mount_plate_w, 4);
        translate([0, 0, -1])
            for (x = [-1, 1])
                translate([x * mount_boss_spacing / 2, 0, 0])
                    cylinder(d = mount_screw_clearance_d, h = mount_plate_t + 2);
    }
}

// angled leg + foot: a wedge hulled between a strip at the plate's bottom
// edge and a flat foot further down and back, so the foot's underside
// stays flat on the counter while the wedge itself carries the tilt.
module leg() {
    foot_drop = leg_depth * tan(tilt_deg);
    hull() {
        translate([0, -mount_plate_w / 2, 0])
            cube([foot_w, 4, 4], center = true);
        translate([0, -mount_plate_w / 2 - foot_drop, -leg_depth])
            cube([foot_w, foot_t, 10], center = true);
    }
}

union() {
    translate([0, 0, -mount_plate_t])
        mount_plate();
    leg();
}
