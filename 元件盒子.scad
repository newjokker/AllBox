/*
 * 元件盒子 - 摩擦插柱连接
 *
 * 坐标约定：
 *   PCB 中心为螺丝柱坐标原点，单位 mm。
 *   下盒螺丝柱保留中心母孔；上盖使用实心插柱直接压入母孔。
 */

/* [PCB 与盒内间隙 / PCB and Inner Clearance] */
pcb_width = 20.10;              // PCB 横向尺寸，沿 X 方向 [5:0.1:180]
pcb_length = 50.00;             // PCB 纵向尺寸，沿 Y 方向 [5:0.1:140]
pcb_clearance_left = 2;         // PCB 左边到盒子内壁距离 [0.5:0.5:30]
pcb_clearance_right = 2;        // PCB 右边到盒子内壁距离 [0.5:0.5:30]
pcb_clearance_front = 2;        // PCB 前边到盒子内壁距离（-Y）[0.5:0.5:30]
pcb_clearance_back = 5;         // PCB 后边到盒子内壁距离（+Y）[0.5:0.5:30]
lower_box_height = 8;           // 下盒高度 [6:0.5:80]
upper_box_height = 8;           // 上盖高度 [4:0.5:60]

/* [盒体结构 / Shell] */
wall_thickness = 2;             // 壁厚 [1:0.2:4]
bottom_thickness = 1.6;         // 下盒底厚 [0.8:0.2:4]
top_thickness = 1.6;            // 上盖顶厚 [0.8:0.2:4]
corner_radius = 4;              // 盒角圆角 [1:0.5:15]
lip_height = 2;                 // 盒口定位唇边高度 [0.5:0.5:5]
lip_fit_gap = 0.25;             // 盒口配合间隙 [0:0.05:0.8]

/* [摩擦插柱 / Friction Pins] */
post_outer_d = 4.8;             // 下盒螺丝柱外径 [3:0.1:10]
post_foot_d = 8.5;              // 下盒柱脚外径 [5:0.1:16]
lower_post_height = 8;          // 下盒柱高，从内底面起算 [3:0.5:40]
socket_d = 2.0;                 // 下盒母孔直径 [1:0.05:6]
socket_depth = 4.5;             // 下盒母孔深度 [2:0.1:20]
pin_d = 1.95;                   // 插入母孔的细插销直径，略小于 socket_d [0.8:0.05:6]
pin_support_d = 4.2;            // 母孔外侧的粗支撑柱直径，越粗越结实 [2:0.1:10]
pin_insert_depth = 4.0;         // 插入母孔的有效深度 [1:0.1:20]
pin_lead_chamfer = 0.45;        // 插柱导入倒角高度 [0:0.05:2]
post_taper = true;              // 柱体轻微锥形，底部更结实 [true, false]

/* [PCB 定位孔 / PCB Mount Holes] */
post_layout = "spacing";         // [spacing, custom]
pcb_mount_hole_spacing_x = 12;  // spacing 模式 X 孔距 [5:0.5:120]
pcb_mount_hole_spacing_y = 42;  // spacing 模式 Y 孔距 [5:0.5:100]
post_positions_custom = [
    [ 39.05,  24.50],
    [-18.95,  24.50],
    [ 39.05, -24.50],
    [-18.95, -24.50]
];

/* [导线槽 / Wire Slot] */
wire_slot_enabled = false;       // 是否在后侧开导线槽 [true, false]
wire_slot_x = -9;               // 导线槽中心 X 坐标 [-80:0.5:80]
wire_slot_z = 4.5;              // 导线槽中心高度，Z=0 为盒外底面 [1:0.1:40]
wire_slot_width = 16;           // 导线槽宽度 [1:0.5:60]
wire_slot_height = 5;           // 导线槽高度 [1:0.5:30]

/* [预览 / Preview] */
preview_mode = "print";         // [assembly, open, print]
open_distance = 30;             // 打开预览距离 [0:2:100]
print_part_spacing = 12;        // 打印摆放间距 [4:1:40]

/* [Hidden] */
model_resolution = 96;
epsilon = 0.02;
$fn = model_resolution;

inner_width = pcb_width + pcb_clearance_left + pcb_clearance_right;
inner_length = pcb_length + pcb_clearance_front + pcb_clearance_back;
box_width = inner_width + 2 * wall_thickness;
box_length = inner_length + 2 * wall_thickness;

function pcb_center_offset() = [
    (pcb_clearance_left - pcb_clearance_right) / 2,
    (pcb_clearance_front - pcb_clearance_back) / 2
];

function spacing_post_positions() = [
    [ pcb_mount_hole_spacing_x / 2,  pcb_mount_hole_spacing_y / 2],
    [-pcb_mount_hole_spacing_x / 2,  pcb_mount_hole_spacing_y / 2],
    [ pcb_mount_hole_spacing_x / 2, -pcb_mount_hole_spacing_y / 2],
    [-pcb_mount_hole_spacing_x / 2, -pcb_mount_hole_spacing_y / 2]
];

function pcb_relative_post_positions() =
    post_layout == "custom" ? post_positions_custom : spacing_post_positions();

function post_positions() =
    [for (p = pcb_relative_post_positions())
        [p[0] + pcb_center_offset()[0], p[1] + pcb_center_offset()[1]]];

function lower_lip_width() = (wall_thickness - lip_fit_gap) / 2;
function upper_lip_width() = (wall_thickness + lip_fit_gap) / 2;

assert(box_width > 2 * wall_thickness, "box_width 太小");
assert(box_length > 2 * wall_thickness, "box_length 太小");
assert(lip_fit_gap >= 0 && lip_fit_gap < wall_thickness,
    "lip_fit_gap 必须大于等于 0 且小于 wall_thickness");
assert(socket_d > pin_d, "摩擦连接需要 socket_d 略大于 pin_d");
assert(socket_d < post_outer_d, "socket_d 必须小于 post_outer_d");
assert(pin_support_d > socket_d, "pin_support_d 应大于 socket_d，避免整根插柱过细");
assert(socket_depth <= lower_post_height, "socket_depth 不能大于 lower_post_height");
assert(pin_insert_depth <= socket_depth, "pin_insert_depth 不能大于 socket_depth");
assert(post_layout == "spacing" || post_layout == "custom",
    "post_layout 必须是 spacing 或 custom");

for (p = pcb_relative_post_positions())
    assert(len(p) == 2, "每个螺丝柱坐标必须是 [X, Y]");

for (p = post_positions())
    assert(abs(p[0]) + post_foot_d / 2 < inner_width / 2 &&
           abs(p[1]) + post_foot_d / 2 < inner_length / 2,
        str("柱脚超出盒子内壁范围: [", p[0], ", ", p[1], "]"));

module rounded_2d(size_x, size_y, radius) {
    safe_r = min(radius, min(size_x, size_y) / 2 - epsilon);
    offset(r = safe_r)
        square([size_x - 2 * safe_r, size_y - 2 * safe_r], center = true);
}

module rounded_prism(size_x, size_y, height, radius) {
    linear_extrude(height = height)
        rounded_2d(size_x, size_y, radius);
}

module rounded_ring(outer_x, outer_y, ring_width, height, radius) {
    difference() {
        rounded_prism(outer_x, outer_y, height, radius);
        translate([0, 0, -epsilon])
            rounded_prism(
                outer_x - 2 * ring_width,
                outer_y - 2 * ring_width,
                height + 2 * epsilon,
                max(radius - ring_width, epsilon)
            );
    }
}

module wire_slot_mask() {
    if (wire_slot_enabled)
        translate([wire_slot_x, box_length / 2, wire_slot_z])
            cube(
                [wire_slot_width, wall_thickness * 3, wire_slot_height],
                center = true
            );
}

module lower_shell() {
    difference() {
        rounded_prism(box_width, box_length, lower_box_height, corner_radius);
        translate([0, 0, bottom_thickness])
            rounded_prism(
                inner_width,
                inner_length,
                lower_box_height - bottom_thickness + epsilon,
                max(corner_radius - wall_thickness, epsilon)
            );
        wire_slot_mask();
    }

    translate([0, 0, lower_box_height - epsilon])
        rounded_ring(
            box_width,
            box_length,
            lower_lip_width(),
            lip_height + epsilon,
            corner_radius
        );
}

module lower_socket_post() {
    difference() {
        union() {
            cylinder(h = min(2.4, lower_post_height), d1 = post_foot_d, d2 = post_outer_d);
            cylinder(
                h = lower_post_height,
                d1 = post_taper ? post_outer_d * 1.08 : post_outer_d,
                d2 = post_outer_d
            );
        }

        translate([0, 0, lower_post_height - socket_depth])
            cylinder(h = socket_depth + epsilon, d = socket_d);
    }
}

module lower_box() {
    union() {
        lower_shell();
        for (p = post_positions())
            translate([p[0], p[1], bottom_thickness - epsilon])
                lower_socket_post();
    }
}

module lid_shell() {
    difference() {
        rounded_prism(box_width, box_length, upper_box_height, corner_radius);

        translate([0, 0, -epsilon])
            rounded_ring(
                box_width,
                box_length,
                upper_lip_width(),
                lip_height + 2 * epsilon,
                corner_radius
            );

        translate([0, 0, -epsilon])
            rounded_prism(
                inner_width,
                inner_length,
                upper_box_height - top_thickness + epsilon,
                max(corner_radius - wall_thickness, epsilon)
            );
    }
}

module friction_pin() {
    pin_length = upper_box_height - top_thickness
        + lower_box_height - bottom_thickness - lower_post_height
        + pin_insert_depth;
    support_h = pin_length - pin_insert_depth;

    translate([0, 0, pin_lead_chamfer])
        cylinder(h = pin_insert_depth - pin_lead_chamfer + epsilon, d = pin_d);

    if (pin_lead_chamfer > 0)
        cylinder(h = pin_lead_chamfer + epsilon, d1 = pin_d * 0.70, d2 = pin_d);

    translate([0, 0, pin_insert_depth - epsilon])
        cylinder(
            h = support_h + 2 * epsilon,
            d1 = pin_support_d * 0.92,
            d2 = pin_support_d
        );
}

module upper_lid() {
    pin_bottom_z = bottom_thickness + lower_post_height
        - lower_box_height - pin_insert_depth;

    union() {
        lid_shell();
        for (p = post_positions())
            translate([p[0], p[1], pin_bottom_z])
                friction_pin();
    }
}

module assembly_view() {
    lower_box();
    translate([0, 0, lower_box_height])
        upper_lid();
}

module open_view() {
    lower_box();
    translate([0, open_distance, lower_box_height])
        upper_lid();
}

module print_view() {
    lower_box();
    translate([box_width + print_part_spacing, 0, upper_box_height])
        rotate([180, 0, 0])
            upper_lid();
}

if (preview_mode == "assembly")
    assembly_view();
else if (preview_mode == "open")
    open_view();
else
    print_view();
