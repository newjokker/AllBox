include <BOSL2/std.scad>
use <螺丝柱盒子参考代码/螺丝柱.scad>
use <螺丝柱盒子参考代码/沉头螺丝孔.scad>

/* [模型尺寸 / Box Size] */
// 盒子外宽，单位 mm
box_width = 70;            // [30:1:160]
// 盒子外长，单位 mm
box_length = 100;          // [40:1:220]
// 上半盒高度，单位 mm
upper_box_height = 12;     // [6:1:60]
// 下半盒高度，单位 mm
lower_box_height = 26;     // [8:1:100]

/* [盒体结构 / Shell] */
// 四周墙壁厚度
wall_thickness = 1.2;        // [1:0.2:3]
// 盒子底盖厚度
bottom_thickness = 1;    // [0.8, 1.0, 1.2, 1.4, 1.6]
// 盒子转角圆角半径
rounding = 5;              // [3:1:15]
// 盒子外侧闭合端转角样式
box_corner_style = "rounded"; // [flat, rounded]
// 上下盒口错开的唇边高度
lip_height = 2;            // [1:0.5:5]
// 上下盒口错开唇边之间的装配间隙
lip_fit_gap = 0.2;         // [0:0.05:0.8]

/* [螺丝连接 / Screw Mounts] */
// 螺丝规格
screw_size = "m3";         // [m2, m2_5, m3, m4, m5]
// 螺丝底孔深度
screw_pilot_depth = 14;    // [4:1:28]
// 盖子下方沉头座主体高度
lid_countersink_body_height = 2; // [1.2:0.2:6]
// 盖子下方沉头座顶部环形凸缘高度
lid_countersink_rim_height = 1.2;  // [0.4:0.2:3]
// 沉头座外径相对沉头孔大端直径的比例
lid_countersink_outer_scale = 1.2; // [1.1:0.05:2]
// 下盒螺丝柱与上盖沉头座底面的装配间隙
screw_stack_clearance = 0.25;       // [0:0.05:1]
// 螺丝柱是否轻微锥形，打印时底部更结实
screw_post_taper = true;   // [true, false]
// 螺丝柱距离盒子内侧边的距离
screw_post_inset = 10;     // [6:1:22]

/* [加强筋 / Ribs] */
// 是否增加盒体内部加强筋
ribs_enabled = true;       // [true, false]
// X 方向加强筋位置，数组值表示相对盒子中心的 X 偏移
rib_x_offsets = [-18, 0, 18];
// Y 方向加强筋位置，数组值表示相对盒子中心的 Y 偏移
rib_y_offsets = [-25, 0, 25];
// 加强筋壁厚
rib_thickness = 0.8;         // [0.6:0.1:2.5]

/* [Hidden] */

// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 128;     // [48, 64, 96, 128]

// 预览模式
preview_mode = "print";    // [open, cutaway, print]
// 预览时上盖沿 Y 方向拉开的距离，0 表示完全合上
open_distance = 38;        // [0:2:190]
// 打印模式中下盒和翻面上盖之间的距离
print_part_spacing = 12;   // [4:1:40]

$fn = model_resolution;

upper_box_size = [box_width, box_length, upper_box_height];
lower_box_size = [box_width, box_length, lower_box_height];

function screw_boss_foot_h(type) =
    type == "m2"   ? 2.4 :
    type == "m2_5" ? 2.6 :
    type == "m3"   ? 3.2 :
    type == "m4"   ? 4.0 :
    type == "m5"   ? 4.8 :
    assert(false, str("unsupported screw_size: ", type));

function post_positions(size) = [
    [ size.x / 2 - screw_post_inset,  size.y / 2 - screw_post_inset],
    [-size.x / 2 + screw_post_inset,  size.y / 2 - screw_post_inset],
    [ size.x / 2 - screw_post_inset, -size.y / 2 + screw_post_inset],
    [-size.x / 2 + screw_post_inset, -size.y / 2 + screw_post_inset]
];

function lid_mount_total_height() =
    lid_countersink_body_height + lid_countersink_rim_height;

function resolved_post_height() =
    let (
        h = lower_box_size.z
            + upper_box_size.z
            - bottom_thickness * 2
            - lid_mount_total_height()
            - screw_stack_clearance
    )
    assert(
        h > screw_boss_foot_h(screw_size),
        "lower_box_size.z is too small for the calculated lower screw boss height"
    )
    h;

function resolved_pilot_depth() =
    min(screw_pilot_depth, resolved_post_height() - 0.2);

function print_lid_x_offset() =
    lower_box_size.x / 2 + upper_box_size.x / 2 + print_part_spacing;

function checked_lip_fit_gap(w) =
    assert(lip_fit_gap >= 0, "lip_fit_gap must be >= 0")
    assert(lip_fit_gap < w, "lip_fit_gap must be smaller than wall_thickness")
    lip_fit_gap;

function lower_lip_width(w) =
    (w - checked_lip_fit_gap(w)) / 2;

function upper_lip_width(w) =
    (w + checked_lip_fit_gap(w)) / 2;

function closed_end_edges(closed_end) =
    closed_end == "top"
        ? [TOP, FRONT+LEFT, FRONT+RIGHT, BACK+LEFT, BACK+RIGHT]
        : [BOTTOM, FRONT+LEFT, FRONT+RIGHT, BACK+LEFT, BACK+RIGHT];

function inner_space_size(outer_size, wall) = [
    outer_size.x - wall * 2,
    outer_size.y - wall * 2
];

function inner_space_rounding(corner_r, wall) =
    max(corner_r - wall, 0.01);

function assembled_inner_z() =
    lower_box_size.z + upper_box_size.z - bottom_thickness * 2;

function assembled_inner_z_center_for_lower() =
    (bottom_thickness + lower_box_size.z + upper_box_size.z - bottom_thickness) / 2;

function assembled_inner_z_center_for_upper() =
    (upper_box_size.z - lower_box_size.z) / 2;

function rib_node_inner_d() =
    rib_thickness * 2;

function rib_node_outer_d() =
    rib_thickness * 4;

function rib_height() =
    rib_thickness;

module rounded_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    bottom_t=2,
    corner_r=8
) {
    cuboid(
        [outer_size.x, outer_size.y, bottom_t],
        rounding=corner_r,
        edges="Z",
        anchor=BOT
    );

    translate([0, 0, bottom_t])
        rect_tube(
            size=outer_size,
            wall=wall,
            h=box_height - bottom_t,
            rounding=corner_r,
            anchor=BOT
        );
}


module box_edge_rib(size=[10, 12], corner_r=3) {
    rect_tube(
        size=size,
        wall=rib_thickness,
        h=rib_height(),
        rounding=min(corner_r, max(min(size.x, size.y) / 2 - rib_thickness, 0.01)),
        anchor=CENTER
    );
}


module assembled_xz_rib(y_pos=0, z_center=0) {
    translate([0, y_pos, z_center])
        rotate([90, 0, 0])
            box_edge_rib(
                size=[
                    inner_space_size(lower_box_size, wall_thickness).x,
                    assembled_inner_z()
                ],
                corner_r=inner_space_rounding(rounding, wall_thickness)
            );
}


module assembled_yz_rib(x_pos=0, z_center=0) {
    translate([x_pos, 0, z_center])
        rotate([90, 0, 90])
            box_edge_rib(
                size=[
                    inner_space_size(lower_box_size, wall_thickness).y,
                    assembled_inner_z()
                ],
                corner_r=inner_space_rounding(rounding, wall_thickness)
            );
}


module rib_node_ring(h=10) {
    difference() {
        cylinder(
            h=h,
            r=rib_node_outer_d() / 2,
            center=true
        );

        cylinder(
            h=h + 0.02,
            r=rib_node_inner_d() / 2,
            center=true
        );
    }
}


module assembled_rib_set(z_center=0) {
    if (ribs_enabled && (len(rib_x_offsets) > 0 || len(rib_y_offsets) > 0)) {
        difference() {
            union() {
                for (y = rib_y_offsets)
                    assembled_xz_rib(y, z_center);

                for (x = rib_x_offsets)
                    assembled_yz_rib(x, z_center);
            }

            for (x = rib_x_offsets)
                for (y = rib_y_offsets)
                    translate([x, y, z_center])
                        cylinder(
                            h=assembled_inner_z() + 0.02,
                            r=rib_node_outer_d() / 2,
                            center=true
                        );
        }
    }
}


module rib_node_set(z_pos=0) {
    if (ribs_enabled && len(rib_x_offsets) > 0 && len(rib_y_offsets) > 0)
        for (x = rib_x_offsets)
            for (y = rib_y_offsets)
                translate([x, y, z_pos])
                    rib_node_ring(rib_height());
}


module clipped_lower_ribs() {
    union() {
        intersection() {
            assembled_rib_set(assembled_inner_z_center_for_lower());

            translate([0, 0, (bottom_thickness + lower_box_size.z + lip_height) / 2])
                cuboid(
                    [
                        lower_box_size.x - wall_thickness * 2,
                        lower_box_size.y - wall_thickness * 2,
                        lower_box_size.z + lip_height - bottom_thickness
                    ],
                    anchor=CENTER
                );
        }

        rib_node_set(bottom_thickness + rib_height() / 2);
    }
}


module clipped_upper_ribs() {
    union() {
        intersection() {
            assembled_rib_set(assembled_inner_z_center_for_upper());

            translate([0, 0, (lip_height + upper_box_size.z - bottom_thickness) / 2])
                cuboid(
                    [
                        upper_box_size.x - wall_thickness * 2,
                        upper_box_size.y - wall_thickness * 2,
                        upper_box_size.z - bottom_thickness - lip_height
                    ],
                    anchor=CENTER
                );
        }

        rib_node_set(upper_box_size.z - bottom_thickness - rib_height() / 2);
    }
}


module rounded_closed_end_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    closed_t=2,
    corner_r=8,
    closed_end="bottom"
) {
    inner_size = [
        outer_size.x - wall * 2,
        outer_size.y - wall * 2,
        box_height - closed_t + 0.02
    ];
    inner_z = closed_end == "top" ? -0.01 : closed_t;
    inner_r = max(corner_r - wall, 0.01);
    round_edges = closed_end_edges(closed_end);

    difference() {
        cuboid(
            [outer_size.x, outer_size.y, box_height],
            rounding=corner_r,
            edges=round_edges,
            anchor=BOT
        );

        translate([0, 0, inner_z])
            cuboid(
                inner_size,
                rounding=inner_r,
                edges=round_edges,
                anchor=BOT
            );
    }
}


module flat_closed_end_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    closed_t=2,
    corner_r=8,
    closed_end="bottom"
) {
    if (closed_end == "top") {
        rect_tube(
            size=outer_size,
            wall=wall,
            h=box_height - closed_t,
            rounding=corner_r,
            anchor=BOT
        );

        translate([0, 0, box_height - closed_t])
            cuboid(
                [outer_size.x, outer_size.y, closed_t],
                rounding=corner_r,
                edges="Z",
                anchor=BOT
            );
    } else {
        rounded_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            bottom_t=closed_t,
            corner_r=corner_r
        );
    }
}


module selectable_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    closed_t=2,
    corner_r=8,
    closed_end="bottom"
) {
    if (box_corner_style == "rounded")
        rounded_closed_end_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            closed_t=closed_t,
            corner_r=corner_r,
            closed_end=closed_end
        );
    else
        flat_closed_end_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            closed_t=closed_t,
            corner_r=corner_r,
            closed_end=closed_end
        );
}


module lower_lipped_box_shell(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    bottom_t=2,
    corner_r=8,
    lip_h=2,
    lip_w=1
) {
    selectable_open_box(
        outer_size=outer_size,
        box_height=box_height,
        wall=wall,
        closed_t=bottom_t,
        corner_r=corner_r,
        closed_end="bottom"
    );

    translate([0, 0, box_height])
        rect_tube(
            size=[
                outer_size.x - wall * 2 + lip_w * 2,
                outer_size.y - wall * 2 + lip_w * 2
            ],
            wall=lip_w,
            h=lip_h,
            rounding=max(corner_r - wall + lip_w, 1),
            anchor=BOT
        );
}


module upper_recessed_box_shell(
    outer_size=[100, 80],
    box_height=20,
    wall=2,
    top_t=2,
    corner_r=8,
    lip_h=2,
    lip_w=1
) {
    difference() {
        selectable_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            closed_t=top_t,
            corner_r=corner_r,
            closed_end="top"
        );

        translate([0, 0, -0.01])
            rect_tube(
                size=[
                    outer_size.x - wall * 2 + lip_w * 2,
                    outer_size.y - wall * 2 + lip_w * 2
                ],
                wall=lip_w + 0.01,
                h=lip_h + 0.02,
                rounding=max(corner_r - wall + lip_w, 1),
                anchor=BOT
            );
    }
}


module lower_screw_post() {
    screw_boss(
        boss_h = resolved_post_height(),
        screw_size = screw_size,
        pilot_h = resolved_pilot_depth(),
        tapered = screw_post_taper,
        entry_chamfer = true
    );
}


module lower_box() {
    union() {
        lower_box_shell();
        lower_screw_posts();
        lower_box_ribs();
    }
}


module lower_box_shell() {
    lower_lipped_box_shell(
        outer_size=[lower_box_size.x, lower_box_size.y],
        box_height=lower_box_size.z,
        wall=wall_thickness,
        bottom_t=bottom_thickness,
        corner_r=rounding,
        lip_h=lip_height,
        lip_w=lower_lip_width(wall_thickness)
    );
}


module lower_box_ribs() {
    clipped_lower_ribs();
}


module lower_screw_posts() {
    for (p = post_positions(lower_box_size)) {
        translate([p.x, p.y, bottom_thickness])
            lower_screw_post();
    }
}


module open_preview() {
    lower_box();

    translate([0, open_distance, lower_box_size.z])
        upper_lid();
}


module closed_assembly_view() {
    lower_box();

    translate([0, 0, lower_box_size.z])
        upper_lid();
}


module cutaway_preview() {
    intersection() {
        closed_assembly_view();

        translate([
            lower_box_size.x / 4,
            0,
            lower_box_size.z / 2
        ])
            cuboid(
                [
                    lower_box_size.x / 2,
                    lower_box_size.y + 20,
                    (lower_box_size.z + upper_box_size.z) * 2
                ],
                anchor=CENTER
            );
    }
}


module print_preview() {
    lower_box();

    translate([print_lid_x_offset(), 0, upper_box_size.z])
        rotate([180, 0, 0])
            upper_lid();
}


module lid_shell() {
    union() {
        upper_recessed_box_shell(
            outer_size=[upper_box_size.x, upper_box_size.y],
            box_height=upper_box_size.z,
            wall=wall_thickness,
            top_t=bottom_thickness,
            corner_r=rounding,
            lip_h=lip_height,
            lip_w=upper_lip_width(wall_thickness)
        );

        upper_lid_ribs();
    }
}


module upper_lid_ribs() {
    clipped_upper_ribs();
}


module lid_screw_cut() {
    // countersink_mount_cut_mask 的约定：z=0 是板子下表面，向上切。
    countersink_mount_cut_mask(
        screw_size = screw_size,
        cut_depth = bottom_thickness + 0.02
    );
}


module lid_countersink_mount() {
    translate([0, 0, -lid_mount_total_height()])
        countersink_mount_part(
            body_height = lid_countersink_body_height,
            screw_size = screw_size,
            outer_diameter_scale = lid_countersink_outer_scale,
            rim_height = lid_countersink_rim_height,
            through = true
        );
}


module upper_lid() {
    union() {
        difference() {
            lid_shell();

            for (p = post_positions(lower_box_size))
                translate([p.x, p.y, upper_box_size.z - bottom_thickness])
                    lid_screw_cut();
        }

        for (p = post_positions(lower_box_size))
            translate([p.x, p.y, upper_box_size.z - bottom_thickness])
                lid_countersink_mount();
    }
}


// ---------------- 主体预览 ----------------

if (preview_mode == "cutaway")
    cutaway_preview();
else if (preview_mode == "print")
    print_preview();
else
    open_preview();
