include <BOSL2/std.scad>

/*
 * ESP32 壳体统一入口。
 *
 * 板型参数由 webapp/configs/*.json 保存，并由服务通过 OpenSCAD -D 注入。
 * 这里的数值只作为直接打开本文件时的 C3 示例和缺省值；建模逻辑位于
 * esp32_shell_core.scad，不再为每块开发板复制一份 SCAD 脚本。
 */

part = "both";
layout = "print";

wall = 2;
bottom_t = 1.6;
top_t = 1.6;
corner_r = 2;
lip_h = 2.4;
epsilon = 0.04;
$fn = 64;

pcb_size = [18.29, 38.86, 1.52];
board_clearance = 0.5;
box_width = pcb_size[0] + board_clearance;
box_length = pcb_size[1] + board_clearance;
base_height = 6;
lid_height = 4;
fit_gap = 0.08;

typec_enabled = true;
typec_cutout_matrix = [["front", 0, 1.5, 11, 4, 1.4, 4]];
side_rect_cutout_matrix = [["back", 0, 1.6, 16.79, 3.5, 0.6]];
side_rect_cutout_depth = 4;

snap_bump_matrix = [
    ["right", -12, 7.6], ["right", 12, 7.6],
    ["left", -12, 7.6], ["left", 12, 7.6],
    ["front", 0, 7.6], ["back", 0, 7.6]
];

pin_length = 32;
pin_row_matrix = [
    [-7.6, -3.58, 32],
    [ 7.6, -3.58, 32]
];
pin_slot_width = 3;
pin_exposed_length = 2;
pcb_support_matrix = [];

button_matrix = [
    [-2.25, -4.18, 180, 3.5, 11.5],
    [ 2.25, -4.18, 180, 3.5, 11.5]
];
button_pad_diameter = 4;
button_flexure_length = 11.5;
button_flexure_width = 3.2;
button_slot_width = 0.4;
button_plunger_diameter = 2.6;
button_root_diameter = 3.1;
button_root_height = 1.45;

lid_fix_post_matrix = [[0, 12, 3, 7.2, 4.6, 1.2]];
lid_fix_post_vent_clearance = 1;

vent_enabled = true;
vent_auto_fill = false;
vent_center = [0, 10];
vent_rows = 4;
vent_columns = 5;
vent_hole_diameter = 3.3;
vent_pitch = [4, 4.8];
vent_area_size = [32, 32];
vent_edge_clearance = 1;
button_vent_clearance = 1;
top_cutout_vent_clearance = 1;

include <esp32_shell_core.scad>

show_model();
