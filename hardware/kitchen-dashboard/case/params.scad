// Shared dimensions for the kitchen dashboard case + accessories.
// Measured from the physical board (2026-09-12) unless noted "estimate".

// --- board (DIYmalls/Sunton ESP32-8048S043C) ---
board_l = 123.23;
board_w = 74;
board_pcb_t = 2.5;
board_stack_t = 8.5;       // full depth incl. display glass + tallest connector
screen_active_l = 105.55;
screen_active_w = 67.29;

// Corner mounting hole inset from each board edge — estimated from photos,
// NOT measured directly. Verify against the physical board before printing
// the first standoff test piece.
board_hole_inset = 6;
board_hole_d = 3.2;        // clearance hole for M3
standoff_od = 6;
standoff_pilot_d = 2.5;    // self-tapping pilot for M3 into a printed standoff

// --- case shell ---
wall_t = 2.4;
corner_r = 6;
bezel_margin_lr = 9;       // left/right front-face margin
bezel_margin_bottom = 9;   // bottom front-face margin
bezel_margin_top = 30;     // extra room up top so the PIR bore clears the screen

case_outer_l = board_l + 2 * bezel_margin_lr;                    // 141.23
case_outer_w = board_w + bezel_margin_top + bezel_margin_bottom; // 113

// The board+screen assembly sits off-center in y within the taller case,
// shifted down by half the top/bottom margin difference. Applied to the
// screen cutout AND the board standoffs so they stay aligned to each other.
board_center_y_offset = -(bezel_margin_top - bezel_margin_bottom) / 2; // -10.5

board_zone_depth = board_stack_t + 3;        // clearance behind board face
electronics_bay_depth = 20;                  // MT3608 + AA holder + wiring
case_depth = wall_t + board_zone_depth + electronics_bay_depth + wall_t; // ~37.9

// --- screen cutout (front face) ---
// Slight overlap onto the board's own black bezel hides print-edge
// roughness and print tolerance without covering active pixels.
screen_cutout_l = screen_active_l + 2;
screen_cutout_w = screen_active_w + 2;

// --- PIR bore (front face, centered in the top margin, above the screen) ---
pir_bore_d = 24;          // HC-SR501 dome ~23mm + clearance
pir_bore_y = case_outer_w / 2 - pir_bore_d / 2 - 1; // 1mm clear of the outer edge

// --- battery access hatch (rear face) ---
// Sized for a 3xAA holder (~53 x 16mm typical) plus margin.
hatch_l = 66;
hatch_w = 26;

// --- mount accessory interface (shared by wall_hanger.scad and stand.scad) ---
// Two M3 heat-set insert bosses on the case's exterior back face.
mount_boss_spacing = 60;   // x-distance between the two bosses
mount_boss_y = -15;        // offset from vertical center (negative = toward top)
mount_boss_insert_d = 4.6; // M3 brass heat-set insert OD
mount_boss_od = 9;
mount_screw_clearance_d = 3.4;
