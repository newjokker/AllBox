include <BOSL2/std.scad>

$fn = 64;


// -------------------------
// 角落磁铁座
// -------------------------
//
// leg_len      : 磁铁座直角边长度
// holder_height: 磁铁座向下延伸的高度
// magnet_diam  : 磁铁直径
// magnet_depth : 磁铁孔深度
// corner_r     : 对应盒子圆角半径
//
module corner_magnet_holder(
    leg_len = 25,
    holder_height = 20,
    magnet_diam = 8,
    magnet_depth = 3,
    corner_r = 5
){
    // 磁铁中心：等腰直角三角形底面的内心
    magnet_center_offset = leg_len * (2 - sqrt(2)) / 2;

    // 三角锥顶点
    holder_points = [
        [0, 0, 0],
        [leg_len, 0, 0],
        [0, leg_len, 0],
        [0, 0, -holder_height]
    ];

    // 三角锥面
    holder_faces = [
        [0, 2, 1],
        [0, 1, 3],
        [0, 3, 2],
        [1, 2, 3]
    ];

    difference(){

        intersection(){

            // 原始三角锥
            polyhedron(
                points = holder_points,
                faces = holder_faces
            );

            // 用单圆角矩形柱裁剪靠近盒子圆角的那个角
            translate([leg_len / 2, leg_len / 2, -holder_height / 2])
                cuboid(
                    [leg_len, leg_len, holder_height + 0.02],
                    rounding = corner_r,
                    edges = [FRONT + LEFT],
                    anchor = CENTER
                );
        }

        // 磁铁孔
        translate([
            magnet_center_offset,
            magnet_center_offset,
            -magnet_depth - 0.01
        ])
            cylinder(
                d = magnet_diam,
                h = magnet_depth + 0.02
            );
    }
}


// -------------------------
// 圆角空心盒子
// -------------------------
//
// outer_size : 盒子外尺寸 [X, Y]
// box_height : 盒子高度
// wall       : 壁厚
// bottom_t   : 底厚
// corner_r   : 外圆角半径
//
module rounded_open_box(
    outer_size = [100, 80],
    box_height = 35,
    wall = 2,
    bottom_t = 2,
    corner_r = 8
){
    // 底板
    cuboid(
        [outer_size.x, outer_size.y, bottom_t],
        rounding = corner_r,
        edges = "Z",
        anchor = BOTTOM
    );

    // 四周侧壁
    translate([0, 0, bottom_t])
        rect_tube(
            size = outer_size,
            wall = wall,
            h = box_height - bottom_t,
            rounding = corner_r,
            anchor = BOTTOM
        );
}


// -------------------------
// 四角磁铁座
// -------------------------
//
// 磁铁座安装在盒子内部四个角，
// 顶面和盒子顶部齐平，然后向下延伸。
//
module four_corner_magnet_holders(
    outer_size = [100, 80],
    box_height = 35,
    wall = 2,
    holder_leg_len = 25,
    holder_height = 20,
    magnet_diam = 8,
    magnet_depth = 3,
    corner_r = 8
){
    inner_corner_x = outer_size.x / 2 - wall;
    inner_corner_y = outer_size.y / 2 - wall;

    // 左前角
    translate([-inner_corner_x, -inner_corner_y, box_height])
        rotate([0, 0, 0])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall
            );

    // 右前角
    translate([inner_corner_x, -inner_corner_y, box_height])
        rotate([0, 0, 90])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall
            );

    // 右后角
    translate([inner_corner_x, inner_corner_y, box_height])
        rotate([0, 0, 180])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall
            );

    // 左后角
    translate([-inner_corner_x, inner_corner_y, box_height])
        rotate([0, 0, 270])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall
            );
}


// -------------------------
// 总装示例
// -------------------------

box_outer_size = [50, 40];
box_height = 20;
wall_thickness = 1;
bottom_thickness = 1;
box_corner_r = 5;

magnet_holder_leg = 10;
magnet_holder_height = 8;
magnet_diameter = 2.5;
magnet_depth = 1;


union(){

    // 盒子本体
    rounded_open_box(
        outer_size = box_outer_size,
        box_height = box_height,
        wall = wall_thickness,
        bottom_t = bottom_thickness,
        corner_r = box_corner_r
    );

    // 四个角的磁铁座
    four_corner_magnet_holders(
        outer_size = box_outer_size,
        box_height = box_height,
        wall = wall_thickness,
        holder_leg_len = magnet_holder_leg,
        holder_height = magnet_holder_height,
        magnet_diam = magnet_diameter,
        magnet_depth = magnet_depth,
        corner_r = box_corner_r
    );
}