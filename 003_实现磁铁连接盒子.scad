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
// fixing_mode  : glue 为普通胶水孔，crush_ribs 为 Gridfinity 风格压溃筋免胶固定
// corner_r     : 对应盒子圆角半径
//
module corner_magnet_holder(
    leg_len = 25,
    holder_height = 20,
    magnet_diam = 8,
    magnet_depth = 3,
    corner_r = 5,
    fixing_mode = "crush_ribs",
    hole_slop = 0.08,
    rib_depth = 0.08,
    rib_count = 3,
    rib_resolution = 72,
    chamfer = 0.25
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
            0
        ])
            magnet_socket_cut(
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                fixing_mode = fixing_mode,
                hole_slop = hole_slop,
                rib_depth = rib_depth,
                rib_count = rib_count,
                rib_resolution = rib_resolution,
                chamfer = chamfer
            );
    }
}


// -------------------------
// 磁铁孔
// -------------------------
//
// glue       : 普通直孔，适合滴胶固定
// crush_ribs : Gridfinity 风格压溃筋，孔内有几条微小内凸筋，磁铁压入后免胶固定
//
module magnet_socket_cut(
    magnet_diam = 8,
    magnet_depth = 3,
    fixing_mode = "crush_ribs",
    hole_slop = 0.08,
    rib_depth = 0.08,
    rib_count = 3,
    rib_resolution = 72,
    chamfer = 0.25
){
    if (fixing_mode == "glue") {
        translate([0, 0, -magnet_depth - 0.01])
            cylinder(
                d = magnet_diam + hole_slop,
                h = magnet_depth + 0.02
            );
    }
    else {
        hole_r = (magnet_diam + hole_slop) / 2;
        chamfer_h = min(chamfer, magnet_depth * 0.45);

        union() {
            // 主体孔带几条很浅的内凸筋。打印时筋会被磁铁压溃，形成免胶摩擦固定。
            translate([0, 0, -magnet_depth - 0.01])
                linear_extrude(height = magnet_depth + 0.02)
                    polygon(points=[
                        for (i=[0:1:rib_resolution - 1])
                            let (
                                a = 360 * i / rib_resolution,
                                rib = max(0, cos(a * rib_count)),
                                r = hole_r - rib_depth * rib
                            )
                            [r * cos(a), r * sin(a)]
                    ]);

            // 入口倒角，方便磁铁找正并压入。
            translate([0, 0, -chamfer_h - 0.01])
                cylinder(
                    d1 = magnet_diam + hole_slop,
                    d2 = magnet_diam + hole_slop + chamfer * 2,
                    h = chamfer_h + 0.02
                );
        }
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
    corner_r = 8,
    fixing_mode = "crush_ribs",
    hole_slop = 0.08,
    rib_depth = 0.08,
    rib_count = 3,
    rib_resolution = 72,
    chamfer = 0.25
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
                corner_r = corner_r - wall,
                fixing_mode = fixing_mode,
                hole_slop = hole_slop,
                rib_depth = rib_depth,
                rib_count = rib_count,
                rib_resolution = rib_resolution,
                chamfer = chamfer
            );

    // 右前角
    translate([inner_corner_x, -inner_corner_y, box_height])
        rotate([0, 0, 90])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall,
                fixing_mode = fixing_mode,
                hole_slop = hole_slop,
                rib_depth = rib_depth,
                rib_count = rib_count,
                rib_resolution = rib_resolution,
                chamfer = chamfer
            );

    // 右后角
    translate([inner_corner_x, inner_corner_y, box_height])
        rotate([0, 0, 180])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall,
                fixing_mode = fixing_mode,
                hole_slop = hole_slop,
                rib_depth = rib_depth,
                rib_count = rib_count,
                rib_resolution = rib_resolution,
                chamfer = chamfer
            );

    // 左后角
    translate([-inner_corner_x, inner_corner_y, box_height])
        rotate([0, 0, 270])
            corner_magnet_holder(
                leg_len = holder_leg_len,
                holder_height = holder_height,
                magnet_diam = magnet_diam,
                magnet_depth = magnet_depth,
                corner_r = corner_r - wall,
                fixing_mode = fixing_mode,
                hole_slop = hole_slop,
                rib_depth = rib_depth,
                rib_count = rib_count,
                rib_resolution = rib_resolution,
                chamfer = chamfer
            );
}


// -------------------------
// 总装示例
// -------------------------

box_outer_size = [80, 60];
box_height = 20;
wall_thickness = 1;
bottom_thickness = 1;
box_corner_r = 5;

magnet_holder_leg = 12;
magnet_holder_height = 10;

magnet_diameter = 3.5;
magnet_depth = 2;

// 磁铁固定方式："glue" 普通胶水孔，"crush_ribs" Gridfinity 风格压溃筋免胶固定
magnet_fixing_mode = "crush_ribs"; // [glue, crush_ribs]

// 基础磁铁孔余量，越大越松
magnet_hole_slop = 0.12;         // [0:0.02:0.25]

// 压溃筋向孔内凸出的深度，越大越紧
magnet_rib_depth = 0.12;         // [0.02:0.02:0.18]

// 压溃筋数量
magnet_rib_count = 3;            // [3:1:6]

// 压溃筋圆周细分，数值越大越圆滑
magnet_rib_resolution = 36;      // [36:12:120]

// 磁铁孔入口倒角
magnet_chamfer = 0.25;           // [0:0.05:0.6]


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
        corner_r = box_corner_r,
        fixing_mode = magnet_fixing_mode,
        hole_slop = magnet_hole_slop,
        rib_depth = magnet_rib_depth,
        rib_count = magnet_rib_count,
        rib_resolution = magnet_rib_resolution,
        chamfer = magnet_chamfer
    );
}
