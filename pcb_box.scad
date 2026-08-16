/*
 * PCB 螺丝柱盒
 *
 * 坐标约定：
 *   X/Y 偏移均以盒盖中心为 (0, 0)，单位为 mm。
 *   screw_post_gap 是装配后上下螺丝柱端面之间的净空，通常设置为
 *   PCB 厚度加少量装配余量（例如 1.6 mm PCB 可设置为 1.7 mm）。
 */

/* [盒子尺寸 / Box Size] */
// 2 mm 壁厚下，47 - 2*2 = 43 mm 净内部宽度/长度
box_width = 50;                 // [30:1:160]
box_length = 50;                // [30:1:160]
// 闭合后净内部高度：15 + 8.2 - 1.6 - 1.6 = 20 mm
lower_box_height = 20;          // [8:0.1:100]
upper_box_height = 4;         // [4:0.1:60]

/* [盒体结构 / Shell] */
wall_thickness = 2;             // [1:0.2:4]
bottom_thickness = 1.6;         // [0.8:0.2:4]
top_thickness = 1.6;            // [0.8:0.2:4]
corner_radius = 4;              // [1:0.5:15]
lip_height = 2;                 // [0.5:0.5:5]
lip_fit_gap = 0.25;             // [0:0.05:0.8]

/* [PCB 与螺丝柱 / PCB and Screw Posts] */
screw_size = "m2";              // [m2, m2_5, m3, m4]
lower_screw_post_height = 15;    // 下盒内底面到下螺丝柱顶面的高度 [3:0.5:40]
screw_post_gap = 1.8;           // 上下螺丝柱端面净空（PCB 厚度 + 余量）[0.5:0.1:10]
screw_pilot_depth = 6;          // 下螺丝柱底孔深度 [2:0.5:20]
pcb_mount_hole_spacing_x = 38;  // PCB 定位孔横向中心距 [5:0.5:100]
pcb_mount_hole_spacing_y = 38;  // PCB 定位孔纵向中心距 [5:0.5:100]
screw_post_taper = true;        // [true, false]

/* [盒盖自定义孔 / Lid Holes] */
lid_holes_enabled = true;      // [true, false]
// 每项格式：[相对中心 X 偏移, 相对中心 Y 偏移, 孔直径]
// 示例：[[0, 0, 6], [15, -10, 3.2]]
lid_holes = [[0, 0, 16]];

/* [预览 / Preview] */
preview_mode = "print";         // [assembly, open, print]
open_distance = 30;             // [0:2:100]
print_part_spacing = 12;        // [4:1:40]

/* [Hidden] */
model_resolution = 96;
epsilon = 0.02;
$fn = model_resolution;

// [螺纹底孔直径, 柱外径, 柱脚直径, 上柱通孔直径, 沉头大端直径, 沉头深度]
function screw_dimensions(type) =
    type == "m2"   ? [1.6, 3.8, 6.5, 2.3, 4.4, 1.1] :
    type == "m2_5" ? [2.0, 4.8, 7.5, 2.8, 5.5, 1.35] :
    type == "m3"   ? [2.5, 5.6, 9.0, 3.4, 6.5, 1.55] :
    type == "m4"   ? [3.3, 7.2, 11.5, 4.5, 8.5, 2.0] :
    assert(false, str("不支持的 screw_size: ", type));

screw_dims = screw_dimensions(screw_size);
pilot_d = screw_dims[0];
post_d = screw_dims[1];
post_foot_d = screw_dims[2];
clearance_d = screw_dims[3];
countersink_d = screw_dims[4];
countersink_depth = screw_dims[5];

inner_width = box_width - 2 * wall_thickness;
inner_length = box_length - 2 * wall_thickness;

// 上柱从盖板内表面向下伸出的高度；由下柱高度和 PCB 净空自动计算。
upper_screw_post_height =
    lower_box_height + upper_box_height
    - bottom_thickness - top_thickness
    - lower_screw_post_height - screw_post_gap;

function post_positions() = [
    [ pcb_mount_hole_spacing_x / 2,  pcb_mount_hole_spacing_y / 2],
    [-pcb_mount_hole_spacing_x / 2,  pcb_mount_hole_spacing_y / 2],
    [ pcb_mount_hole_spacing_x / 2, -pcb_mount_hole_spacing_y / 2],
    [-pcb_mount_hole_spacing_x / 2, -pcb_mount_hole_spacing_y / 2]
];

// 与参考模型一致：下盒唇边和上盖凹槽各占一部分壁厚，
// 两者宽度之差形成装配间隙。
function lower_lip_width() = (wall_thickness - lip_fit_gap) / 2;
function upper_lip_width() = (wall_thickness + lip_fit_gap) / 2;

assert(box_width > 2 * wall_thickness, "box_width 太小");
assert(box_length > 2 * wall_thickness, "box_length 太小");
assert(corner_radius > 0, "corner_radius 必须大于 0");
assert(lower_screw_post_height > 0, "lower_screw_post_height 必须大于 0");
assert(screw_post_gap >= 0, "screw_post_gap 不能小于 0");
assert(lip_fit_gap >= 0 && lip_fit_gap < wall_thickness,
    "lip_fit_gap 必须大于等于 0 且小于 wall_thickness");
assert(upper_screw_post_height > 0,
    "盒内高度不足：请减小 lower_screw_post_height 或 screw_post_gap，或增加盒高");
assert(screw_pilot_depth <= lower_screw_post_height,
    "screw_pilot_depth 不能大于 lower_screw_post_height");
assert(pcb_mount_hole_spacing_x / 2 + post_foot_d / 2 < box_width / 2,
    "PCB 横向孔距过大，螺丝柱会伸出盒外");
assert(pcb_mount_hole_spacing_y / 2 + post_foot_d / 2 < box_length / 2,
    "PCB 纵向孔距过大，螺丝柱会伸出盒外");

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
    }

    // 唇边外沿与盒体外沿重合，因此会与盒壁可靠连接。
    translate([0, 0, lower_box_height - epsilon])
        rounded_ring(
            box_width,
            box_length,
            lower_lip_width(),
            lip_height + epsilon,
            corner_radius
        );
}

module lower_screw_post() {
    difference() {
        union() {
            cylinder(h = min(2.4, lower_screw_post_height), d1 = post_foot_d, d2 = post_d);
            cylinder(
                h = lower_screw_post_height,
                d1 = screw_post_taper ? post_d * 1.08 : post_d,
                d2 = post_d
            );
        }

        translate([0, 0, lower_screw_post_height - screw_pilot_depth])
            cylinder(h = screw_pilot_depth + epsilon, d = pilot_d);
    }
}

module lower_box() {
    union() {
        lower_shell();
        for (p = post_positions())
            translate([p[0], p[1], bottom_thickness - epsilon])
                lower_screw_post();
    }
}

module lid_shell() {
    difference() {
        rounded_prism(box_width, box_length, upper_box_height, corner_radius);

        // 从上盖开口端切出与下盒唇边配合的阶梯凹槽。
        // upper_lip_width 比 lower_lip_width 大 lip_fit_gap。
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

module upper_screw_post_solid() {
    // z=0 为上柱底端，柱顶与盖板内表面相接。
    cylinder(
        h = upper_screw_post_height + epsilon,
        d1 = post_d,
        d2 = screw_post_taper ? post_d * 1.08 : post_d
    );
}

module screw_clearance_and_countersink_mask() {
    // 通孔贯穿上螺丝柱和盖板。
    translate([0, 0, -epsilon])
        cylinder(
            h = upper_screw_post_height + top_thickness + 2 * epsilon,
            d = clearance_d
        );

    // 沉头孔的大端位于盒盖外表面。
    translate([0, 0, upper_screw_post_height + top_thickness - countersink_depth])
        cylinder(
            h = countersink_depth + epsilon,
            d1 = clearance_d,
            d2 = countersink_d
        );
}

module lid_custom_hole_masks() {
    if (lid_holes_enabled)
        for (hole = lid_holes) {
            assert(len(hole) == 3, "lid_holes 每项必须为 [X偏移, Y偏移, 直径]");
            assert(hole[2] > 0, "盒盖孔直径必须大于 0");
            translate([hole[0], hole[1], upper_box_height - top_thickness - epsilon])
                cylinder(h = top_thickness + 2 * epsilon, d = hole[2]);
        }
}

module upper_lid() {
    post_bottom_z = upper_box_height - top_thickness - upper_screw_post_height;

    difference() {
        union() {
            lid_shell();
            for (p = post_positions())
                translate([p[0], p[1], post_bottom_z])
                    upper_screw_post_solid();
        }

        for (p = post_positions())
            translate([p[0], p[1], post_bottom_z])
                screw_clearance_and_countersink_mask();

        lid_custom_hole_masks();
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
