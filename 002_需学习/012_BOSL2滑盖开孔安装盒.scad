
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

/* [模型尺寸 / Box Size] */
// 盒子内部宽度，单位 mm
inner_width = 47.5;         // [20:0.5:120]
// 盒子内部长度，单位 mm
inner_length = 62;          // [30:0.5:160]
// 盒子内部高度，单位 mm
inner_height = 16;          // [6:0.5:80]

/* [盒体结构 / Shell] */
// 盒子壁厚，单位 mm
wall_thickness = 1.5;       // [1:0.1:4]
// 盒子内部转角圆角半径，单位 mm
inner_rounding = 2;         // [0:0.5:8]
// 盒体和滑盖槽的装配间隙，单位 mm
fit_clearance = 0.1;        // [0:0.05:0.5]
// 内部尺寸额外宽松量，单位 mm
inner_xy_slop = 0.2;        // [0:0.05:1]
// 内部高度额外宽松量，单位 mm
inner_z_slop = 0.1;         // [0:0.05:1]

/* [滑盖 / Sliding Lid] */
// 盖子预览时高出盒体的距离，单位 mm
lid_preview_lift = 0.2;     // [0:0.1:5]

/* [渲染 / Render] */
// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 64;      // [32, 48, 64, 96, 128]

/* [Hidden] */
$fn = model_resolution;

tkns = wall_thickness;
inner_size = [inner_width, inner_length, inner_height];
inner_ofs_size = inner_size + [inner_xy_slop, inner_xy_slop, inner_z_slop];
box_size = get_box_size(tkns, inner_ofs_size, fit_clearance) + [0, 0, inner_z_slop + tkns];

// https://github.com/BelfrySCAD/BOSL2/wiki

module sliding_lid(tkns, inner_size, inner_rounding, is_mask=false, ofs=0.1) {
    ofs = is_mask ? ofs : 0;

    rd = is_mask ? inner_rounding : inner_rounding + 0.4;

    lid_size_y = inner_size.y + tkns;

    lid_size_top = [inner_size.x, lid_size_y, tkns / 2] - [tkns * 2, tkns, 0] + [ofs * 2, ofs * 2, ofs * 2];
    lid_size_bot = [inner_size.x, lid_size_y, tkns] + [ofs * 2, ofs * 2, ofs * 2];
    face_size = [inner_size.x, inner_size.y, tkns] + [ofs * 2 + tkns * 2, ofs * 2 + tkns * 2, ofs * 2];

    // 滑入盒体槽内的上层导向条。
    ymove(-inner_size.y / 2 - ofs - tkns)
    zmove(tkns * 2 - ofs)
        cuboid(size=lid_size_top, rounding=rd, edges="Z", except=FRONT, anchor=BOTTOM + FRONT);

    // 斜面让滑盖和盒体的槽口更容易配合。
    ymove(-inner_size.y / 2 - ofs - tkns)
    zmove(tkns)
        prismoid(
            [lid_size_bot.x, lid_size_bot.y],
            [lid_size_top.x, lid_size_top.y],
            shift=[0, -tkns / 2],
            rounding=[rd, rd, 0, 0],
            h=tkns,
            anchor=BOTTOM + FRONT
        );

    ymove(-inner_size.y / 2 - ofs - tkns)
    zmove(-ofs)
        cuboid(size=lid_size_bot, rounding=rd, edges="Z", except=FRONT, anchor=BOTTOM + FRONT);

    // 盖子前端挡片，闭合后挡住盒口。
    zmove(-ofs + tkns * 2.5)
        cuboid(size=face_size, anchor=BOTTOM, rounding=inner_rounding + ofs + tkns, edges="Z");
}

function get_lid_height(tkns) = tkns * 2.5;
function get_ofs_inner_size(inner_size, ofs) = inner_size + [ofs * 2, ofs * 2, ofs * 2];
function get_box_size(tkns, inner_size, ofs) =
    get_ofs_inner_size(inner_size, ofs) + [tkns * 2, tkns * 2, tkns + get_lid_height(tkns)];

module sliding_box(tkns, inner_size, inner_rounding, ofs=0.1)
{
    ofs_inner_size = get_ofs_inner_size(inner_size, ofs);
    box_size = get_box_size(tkns, inner_size, ofs);

    difference() {
        cuboid(size=box_size, anchor=BOTTOM, rounding=inner_rounding + ofs + tkns, edges="Z");

        // 内部收纳空间。
        zmove(tkns)
            cuboid(size=ofs_inner_size, anchor=BOTTOM, rounding=inner_rounding, edges="Z");

        // 用滑盖作为负模切出顶部滑槽。
        zmove(tkns + ofs_inner_size.z)
            sliding_lid(tkns, ofs_inner_size, inner_rounding, true);
    }
}

// 盖子
zmove(inner_ofs_size.z + tkns + lid_preview_lift + tkns * 3)
    sliding_lid(tkns, inner_ofs_size, inner_rounding, false, fit_clearance);

// 盒子
sliding_box(tkns, inner_ofs_size, inner_rounding, fit_clearance);
