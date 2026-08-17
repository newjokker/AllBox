/*
 * PCB 螺丝柱盒
 *
 * 坐标约定：
 *   自定义螺丝柱坐标以 PCB 中心为 (0, 0)，单位为 mm。
 *   盒子仍以自身中心建模；当四边间隙不相等时，PCB 会自动偏移。
 *   screw_post_gap 是装配后上下螺丝柱端面之间的净空，通常设置为
 *   PCB 厚度加少量装配余量（本图 PCB 厚 1.60 mm，默认设置为 1.70 mm）。
 */

/* [PCB 与盒内间隙 / PCB and Inner Clearance] */
// 盒子外形由 PCB 尺寸、四边间隙和壁厚自动计算。
// 参考图参数：PCB 外形 85.10 x 56.00 mm；侧向最高器件约 18.10 mm；PCB 厚 1.60 mm。
pcb_width = 85.10;              // PCB 横向尺寸，沿 X 方向 [5:0.1:180]
pcb_length = 56.00;             // PCB 纵向尺寸，沿 Y 方向 [5:0.1:140]
pcb_clearance_left = 2;         // PCB 左边到盒子内壁距离 [0.5:0.5:30]
pcb_clearance_right = 2;        // PCB 右边到盒子内壁距离 [0.5:0.5:30]
pcb_clearance_front = 2;        // PCB 前边到盒子内壁距离（-Y）[0.5:0.5:30]
pcb_clearance_back = 5;         // PCB 后边到盒子内壁距离（+Y）[0.5:0.5:30]
// 闭合后 PCB 上方净空约：22 + 8 - 1.6 - 4.0 - 1.6 = 22.8 mm，可覆盖图中约 18.10 mm 高器件。
lower_box_height = 8;          // [8:0.1:100]
upper_box_height = 8;           // [4:0.1:60]

/* [盒体结构 / Shell] */
wall_thickness = 2;             // [1:0.2:4]
bottom_thickness = 1.6;         // [0.8:0.2:4]
top_thickness = 1.6;            // [0.8:0.2:4]
corner_radius = 4;              // [1:0.5:15]
lip_height = 2;                 // [0.5:0.5:5]
lip_fit_gap = 0.25;             // [0:0.05:0.8]

/* [PCB 与螺丝柱 / PCB and Screw Posts] */
screw_size = "m2_5";              // [m2, m2_5, m3, m4]
lower_screw_post_height = 6;     // 下盒内底面到下螺丝柱顶面的高度 [3:0.5:40]
screw_post_gap = 1.7;           // 上下螺丝柱端面净空（PCB 厚度 + 余量）[0.5:0.1:10]
screw_pilot_depth = 4;          // 下螺丝柱底孔深度 [2:0.5:20]
pcb_mount_hole_spacing_x = 58;  // PCB 定位孔横向中心距 [5:0.5:120]
pcb_mount_hole_spacing_y = 49;  // PCB 定位孔纵向中心距 [5:0.5:100]

// spacing: 用上面的 X/Y 孔距自动生成四角螺丝柱；custom: 使用下面的坐标列表。
screw_post_layout = "custom";   // [spacing, custom]
// 自定义螺丝柱中心坐标，坐标原点是 PCB 中心，格式为 [X, Y]。
// 本图孔位：右侧孔中心距 PCB 右边 3.50 mm，上下孔中心距 PCB 上下边各 3.50 mm；
// 横向孔距 58.00 mm，纵向孔距 49.00 mm，因此四孔相对 PCB 中心并不左右对称。
screw_post_positions_custom = [
    [ 39.05,  24.50],
    [-18.95,  24.50],
    [ 39.05, -24.50],
    [-18.95, -24.50]
];
screw_post_taper = true;        // [true, false]

/* [自定义开孔 / Custom Holes] */
box_holes_enabled = false;      // [true, false]
// 每项格式：
// 圆孔：[面, "circle", 位置1, 位置2, 直径]
// 矩形：[面, "rect", 矩形离中心x的距离, 矩形中心孔y的高度, 宽度, 高度]
// 面：top / bottom / front / back / left / right
// top / bottom：
//   位置1 = X，正数向右；位置2 = Y，正数向后；原点是盒子中心。
// front / back / left / right
//   位置1 = Y，正数向后；位置2 = Z，正数向上；Z=0 是下盒底面。
// 侧面开孔默认切在下盒侧壁上；圆孔的直径、矩形孔的宽高都以孔中心为基准。
box_holes = [
    // ["front", "rect", 0, 9, 6, 3],
    // ["back", "rect", 0, 6, 9, 6],
    // ["left", "rect", -8, 4.6, 9, 6]
];

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
    type == "m2"   ? [1.7, 3.8, 8.5, 2.3, 4.4, 1.1] :
    type == "m2_5" ? [2.0, 4.8, 8.5, 2.8, 5.5, 1.35] :
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

inner_width = pcb_width + pcb_clearance_left + pcb_clearance_right;
inner_length = pcb_length + pcb_clearance_front + pcb_clearance_back;
box_width = inner_width + 2 * wall_thickness;
box_length = inner_length + 2 * wall_thickness;

// 盒子仍以自身中心为原点；PCB 中心按四边间隙自动偏移。
function pcb_center_offset() = [
    (pcb_clearance_left - pcb_clearance_right) / 2,
    (pcb_clearance_front - pcb_clearance_back) / 2
];

// 上柱从盖板内表面向下伸出的高度；由下柱高度和 PCB 净空自动计算。
upper_screw_post_height =
    lower_box_height + upper_box_height
    - bottom_thickness - top_thickness
    - lower_screw_post_height - screw_post_gap;

function spacing_post_positions() = [
    [ pcb_mount_hole_spacing_x / 2,  pcb_mount_hole_spacing_y / 2],
    [-pcb_mount_hole_spacing_x / 2,  pcb_mount_hole_spacing_y / 2],
    [ pcb_mount_hole_spacing_x / 2, -pcb_mount_hole_spacing_y / 2],
    [-pcb_mount_hole_spacing_x / 2, -pcb_mount_hole_spacing_y / 2]
];

function pcb_relative_post_positions() =
    screw_post_layout == "custom"
        ? screw_post_positions_custom
        : spacing_post_positions();

function post_positions() =
    [for (p = pcb_relative_post_positions())
        [p[0] + pcb_center_offset()[0], p[1] + pcb_center_offset()[1]]];

// 与参考模型一致：下盒唇边和上盖凹槽各占一部分壁厚，
// 两者宽度之差形成装配间隙。
function lower_lip_width() = (wall_thickness - lip_fit_gap) / 2;
function upper_lip_width() = (wall_thickness + lip_fit_gap) / 2;

assert(box_width > 2 * wall_thickness, "box_width 太小");
assert(box_length > 2 * wall_thickness, "box_length 太小");
assert(pcb_width > 0 && pcb_length > 0, "PCB 尺寸必须大于 0");
assert(pcb_clearance_left >= 0 && pcb_clearance_right >= 0 &&
       pcb_clearance_front >= 0 && pcb_clearance_back >= 0,
    "PCB 与盒子内壁的四边间隙不能小于 0");
assert(corner_radius > 0, "corner_radius 必须大于 0");
assert(lower_screw_post_height > 0, "lower_screw_post_height 必须大于 0");
assert(screw_post_gap >= 0, "screw_post_gap 不能小于 0");
assert(lip_fit_gap >= 0 && lip_fit_gap < wall_thickness,
    "lip_fit_gap 必须大于等于 0 且小于 wall_thickness");
assert(upper_screw_post_height > 0,
    "盒内高度不足：请减小 lower_screw_post_height 或 screw_post_gap，或增加盒高");
assert(screw_pilot_depth <= lower_screw_post_height,
    "screw_pilot_depth 不能大于 lower_screw_post_height");
assert(screw_post_layout == "spacing" || screw_post_layout == "custom",
    "screw_post_layout 必须是 spacing 或 custom");
assert(len(pcb_relative_post_positions()) > 0, "至少需要一个螺丝柱坐标");
for (p = pcb_relative_post_positions()) {
    if (len(p) == 2)
        assert(abs(p[0]) + post_foot_d / 2 < pcb_width / 2 + max(pcb_clearance_left, pcb_clearance_right) &&
               abs(p[1]) + post_foot_d / 2 < pcb_length / 2 + max(pcb_clearance_front, pcb_clearance_back),
            str("螺丝柱坐标离 PCB 太远或超出盒内空间: [", p[0], ", ", p[1], "]"));
    else
        assert(false, "每个螺丝柱坐标必须是 [X, Y]");
}
for (p = post_positions())
    assert(abs(p[0]) + post_foot_d / 2 < inner_width / 2 &&
           abs(p[1]) + post_foot_d / 2 < inner_length / 2,
        str("螺丝柱柱脚超出盒子内壁范围: [", p[0], ", ", p[1], "]"));

function is_hole_face(face) =
    face == "top" || face == "bottom" ||
    face == "front" || face == "back" ||
    face == "left" || face == "right";

function is_hole_type(type) =
    type == "circle" || type == "rect";

function hole_size_x(hole) =
    hole[1] == "circle" ? hole[4] : hole[4];

function hole_size_y(hole) =
    hole[1] == "circle" ? hole[4] : hole[5];

for (hole = box_holes) {
    assert(len(hole) == 5 || len(hole) == 6,
        "box_holes 每项必须为 [面, 类型, 位置1, 位置2, 尺寸] 或 [面, 类型, 位置1, 位置2, 宽度, 高度]");
    assert(is_hole_face(hole[0]),
        "box_holes 的面必须是 top、bottom、front、back、left 或 right");
    assert(is_hole_type(hole[1]),
        "box_holes 的类型必须是 circle 或 rect");
    assert((hole[1] == "circle" && len(hole) == 5) ||
           (hole[1] == "rect" && len(hole) == 6),
        "circle 使用 5 项，rect 使用 6 项");
    assert(hole_size_x(hole) > 0 && hole_size_y(hole) > 0,
        "box_holes 的孔尺寸必须大于 0");

    if (hole[0] == "top" || hole[0] == "bottom")
        assert(abs(hole[2]) + hole_size_x(hole) / 2 < box_width / 2 &&
               abs(hole[3]) + hole_size_y(hole) / 2 < box_length / 2,
            str("上下表面开孔超出盒子范围: ", hole));
    else if (hole[0] == "front" || hole[0] == "back")
        assert(abs(hole[2]) + hole_size_x(hole) / 2 < box_width / 2 &&
               hole[3] - hole_size_y(hole) / 2 > 0 &&
               hole[3] + hole_size_y(hole) / 2 < lower_box_height,
            str("前后侧面开孔超出下盒范围: ", hole));
    else
        assert(abs(hole[2]) + hole_size_x(hole) / 2 < box_length / 2 &&
               hole[3] - hole_size_y(hole) / 2 > 0 &&
               hole[3] + hole_size_y(hole) / 2 < lower_box_height,
            str("左右侧面开孔超出下盒范围: ", hole));
}

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

module vertical_hole_mask(hole, cut_z, cut_h) {
    if (hole[1] == "circle")
        translate([hole[2], hole[3], cut_z])
            cylinder(h = cut_h, d = hole[4]);
    else
        translate([hole[2], hole[3], cut_z + cut_h / 2])
            cube([hole[4], hole[5], cut_h], center = true);
}

module side_hole_mask(hole) {
    cut_depth = 2 * wall_thickness + 2 * epsilon;

    if (hole[0] == "front")
        translate([hole[2], -box_length / 2, hole[3]])
            if (hole[1] == "circle")
                rotate([90, 0, 0])
                    cylinder(h = cut_depth, d = hole[4], center = true);
            else
                cube([hole[4], cut_depth, hole[5]], center = true);
    else if (hole[0] == "back")
        translate([hole[2], box_length / 2, hole[3]])
            if (hole[1] == "circle")
                rotate([90, 0, 0])
                    cylinder(h = cut_depth, d = hole[4], center = true);
            else
                cube([hole[4], cut_depth, hole[5]], center = true);
    else if (hole[0] == "left")
        translate([-box_width / 2, hole[2], hole[3]])
            if (hole[1] == "circle")
                rotate([0, 90, 0])
                    cylinder(h = cut_depth, d = hole[4], center = true);
            else
                cube([cut_depth, hole[4], hole[5]], center = true);
    else if (hole[0] == "right")
        translate([box_width / 2, hole[2], hole[3]])
            if (hole[1] == "circle")
                rotate([0, 90, 0])
                    cylinder(h = cut_depth, d = hole[4], center = true);
            else
                cube([cut_depth, hole[4], hole[5]], center = true);
}

module lower_box_hole_masks() {
    if (box_holes_enabled)
        for (hole = box_holes)
            if (hole[0] == "bottom")
                vertical_hole_mask(hole, -epsilon, bottom_thickness + 2 * epsilon);
            else
                side_hole_mask(hole);
}

module upper_lid_hole_masks() {
    if (box_holes_enabled)
        for (hole = box_holes)
            if (hole[0] == "top")
                vertical_hole_mask(
                    hole,
                    upper_box_height - top_thickness - epsilon,
                    top_thickness + 2 * epsilon
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

        lower_box_hole_masks();
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

        upper_lid_hole_masks();
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
