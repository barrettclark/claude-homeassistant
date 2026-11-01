// Wall-hanger accessory: screws to the case's 2 mount bosses (see
// params.scad), hangs on 2 wall screws via keyhole slots.

include <params.scad>

$fn = 48;

plate_l = mount_boss_spacing + 40;
plate_w = 40;
plate_t = 4;

wall_screw_spacing = 80;    // distance between the 2 wall screws you drive
keyhole_head_d = 9;         // clears a standard drywall-anchor screw head
keyhole_shaft_w = 4.5;
keyhole_travel = 12;        // slot length the case can drop down onto

module rounded_rect(l, w, r) {
    hull() {
        for (x = [-1, 1], y = [-1, 1])
            translate([x * (l / 2 - r), y * (w / 2 - r)])
                circle(r = r);
    }
}

module keyhole() {
    translate([0, keyhole_travel / 2])
        circle(d = keyhole_head_d);
    translate([-keyhole_shaft_w / 2, -keyhole_travel / 2])
        square([keyhole_shaft_w, keyhole_travel]);
}

difference() {
    linear_extrude(height = plate_t)
        rounded_rect(plate_l, plate_w, 4);

    // screws into the case's mount bosses
    translate([0, 0, -1])
        for (x = [-1, 1])
            translate([x * mount_boss_spacing / 2, 0, 0])
                cylinder(d = mount_screw_clearance_d, h = plate_t + 2);

    // keyholes for the wall screws
    translate([0, 0, -1])
        for (x = [-1, 1])
            translate([x * wall_screw_spacing / 2, 0, 0])
                linear_extrude(height = plate_t + 2)
                    keyhole();
}
