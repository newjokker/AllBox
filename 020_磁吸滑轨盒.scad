include <BOSL2/std.scad>

/* [模型尺寸 / Box Size] */
// 盒子内部宽度，单位 mm
inner_width = 38;           // [20:0.5:120]
// 盒子内部长度，单位 mm
inner_length = 86;          // [40:0.5:180]
// 盒子内部高度，单位 mm
inner_height = 18;          // [6:0.5:80]

/* [盒体结构 / Shell] */
// 盒子壁厚，单位 mm
wall_thickness = 2;         // [1:0.1:4]
// 盒子底厚，单位 mm
bottom_thickness = 1.6;     // [0.8:0.1:4]
// 外部转角圆角半径，单位 mm
outer_rounding = 5;         // [1:0.5:12]
// 内部转角圆角半径，单位 mm
inner_rounding = 3;         // [0:0.5:10]
// 装配间隙，单位 mm
fit_clearance = 0.18;       // [0:0.02:0.6]

/* [滑轨 / Side Rails] */
// 侧面滑槽高度，单位 mm
rail_height = 1.4;          // [0.6:0.1:3]
// 侧面滑槽深度，单位 mm
rail_depth = 1.0;           // [0.4:0.1:2.5]
// 侧面滑轨/滑槽宽度，单位 mm
rail_width = 2.2;           // [1:0.1:5]
// 滑轨距离盒口顶部的距离，单位 mm
rail_top_offset = 2.8;      // [1:0.1:8]
// 滑轨前端入口倒角长度，单位 mm
rail_lead_in = 6;           // [0:0.5:16]

/* [磁铁 / Magnets] */
// 是否生成磁铁孔
enable_magnet_holes = true; // [true, false]
// 磁铁孔直径，单位 mm
magnet_hole_diameter = 6.2; // [3:0.1:12]
// 磁铁孔深度，单位 mm
magnet_hole_depth = 2.2;    // [1:0.1:6]
// 两个磁铁孔中心间距，单位 mm
magnet_spacing = 22;        // [8:0.5:60]
// 磁铁孔距离短边端部的距离，单位 mm
magnet_end_inset = 6;       // [3:0.5:14]

/* [盖子 / Lid] */
// 盖板厚度，单位 mm
lid_thickness = 1.8;        // [1:0.1:4]
// 盖子边缘上翻高度，单位 mm
lid_rim_height = 1.6;       // [0:0.1:4]
// 盖子预览时离底盒的距离，单位 mm
part_spacing = 12;          // [4:1:40]

/* [渲染 / Render] */
// 预览模式
preview_mode = "print";     // [print, assembled, box, lid]
// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 96;      // [48, 64, 96, 128]

/* [Hidden] */
$fn = model_resolution;

box_outer_size = [
    inner_width + wall_thickness * 2,
    inner_length + wall_thickness * 2,
    inner_height + bottom_thickness
];

lid_size = [
    box_outer_size.x - fit_clearance * 2,
    box_outer_size.y - fit_clearance * 2,
    lid_thickness
];

rail_z = box_outer_size.z - rail_top_offset - rail_height / 2;
lid_rail_z = -rail_height / 2;
magnet_y = box_outer_size.y / 2 - magnet_end_inset;


module magnet_holes(depth=2, from_top_z=0) {
    if (enable_magnet_holes) {
        for (x=[-magnet_spacing / 2, magnet_spacing / 2]) {
            translate([x, magnet_y, from_top_z - depth])
                cylinder(d=magnet_hole_diameter, h=depth + 0.02, anchor=BOT);
        }
    }
}


module rounded_open_box() {
    difference() {
        cuboid(
            box_outer_size,
            rounding=outer_rounding,
            edges="Z",
            anchor=BOT
        );

        translate([0, 0, bottom_thickness])
            cuboid(
                [
                    inner_width,
                    inner_length,
                    inner_height + 0.02
                ],
                rounding=inner_rounding,
                edges="Z",
                anchor=BOT
            );

        // 顶部开口留得更干净，避免圆角壳体在盒口产生薄边。
        translate([0, 0, box_outer_size.z - 0.01])
            cuboid(
                [
                    inner_width,
                    inner_length,
                    wall_thickness + 0.04
                ],
                rounding=inner_rounding,
                edges="Z",
                anchor=BOT
            );
    }
}


module side_rail_grooves() {
    groove_len = box_outer_size.y - wall_thickness * 2 - rail_lead_in;
    groove_rounding = max(min(rail_height / 2, rail_depth / 2 - 0.02), 0.01);

    for (side=[-1, 1]) {
        translate([
            side * (box_outer_size.x / 2 - rail_depth / 2 + 0.01),
            -box_outer_size.y / 2 + wall_thickness + rail_lead_in + groove_len / 2,
            rail_z
        ])
            cuboid(
                [
                    rail_depth + 0.04,
                    groove_len,
                    rail_height + fit_clearance
                ],
                anchor=CENTER,
                rounding=groove_rounding,
                edges="Y"
            );
    }
}


module magnet_end_pad() {
    pad_h = bottom_thickness + magnet_hole_depth + 0.6;

    difference() {
        translate([0, box_outer_size.y / 2 - magnet_end_inset, 0])
            cuboid(
                [
                    box_outer_size.x,
                    magnet_end_inset * 2,
                    pad_h
                ],
                rounding=outer_rounding,
                edges="Z",
                anchor=BOT
            );

        magnet_holes(depth=pad_h + 0.02, from_top_z=pad_h + 0.01);
    }
}


module base_box() {
    difference() {
        union() {
            rounded_open_box();
            magnet_end_pad();
        }

        side_rail_grooves();
    }
}


module lid_outline(extra=[0, 0, 0]) {
    cuboid(
        lid_size + extra,
        rounding=max(outer_rounding - fit_clearance, 0.01),
        edges="Z",
        anchor=BOT
    );
}


module lid_side_rails() {
    rail_len = lid_size.y - wall_thickness * 2 - rail_lead_in;

    for (side=[-1, 1]) {
        translate([
            side * (lid_size.x / 2 - rail_width / 2 - fit_clearance),
            -lid_size.y / 2 + wall_thickness + rail_lead_in + rail_len / 2,
            lid_rail_z
        ])
            cuboid(
                [
                    rail_width,
                    rail_len,
                    rail_height
                ],
                rounding=rail_height / 2,
                edges="Y",
                anchor=CENTER
            );
    }
}


module lid_rim() {
    if (lid_rim_height > 0) {
        translate([0, 0, lid_thickness])
            rect_tube(
                size=[
                    lid_size.x - wall_thickness,
                    lid_size.y - wall_thickness
                ],
                wall=wall_thickness / 2,
                h=lid_rim_height,
                rounding=max(outer_rounding - wall_thickness, 0.01),
                anchor=BOT
            );
    }
}


module sliding_lid() {
    difference() {
        union() {
            lid_outline();
            lid_side_rails();
            lid_rim();
        }

        magnet_holes(depth=magnet_hole_depth, from_top_z=lid_thickness + lid_rim_height + 0.01);
    }
}


module assembled_preview() {
    base_box();

    translate([0, 0, box_outer_size.z + fit_clearance])
        sliding_lid();
}


module print_preview() {
    base_box();

    translate([box_outer_size.x + part_spacing, 0, rail_height])
        sliding_lid();
}


if (preview_mode == "box")
    base_box();
else if (preview_mode == "lid")
    sliding_lid();
else if (preview_mode == "assembled")
    assembled_preview();
else
    print_preview();
