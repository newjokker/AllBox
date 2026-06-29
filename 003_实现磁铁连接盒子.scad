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
// fixing_mode  : glue 为普通胶水孔，crush_ribs 为压溃筋免胶固定，snap_tabs 为上沿卡齿免胶固定
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
    rib_count = 8,
    rib_resolution = 72,
    chamfer = 0.25,
    tab_count = 6,
    tab_depth = 0.22,
    tab_resolution = 96
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
                chamfer = chamfer,
                tab_count = tab_count,
                tab_depth = tab_depth,
                tab_resolution = tab_resolution
            );
    }
}


// -------------------------
// 磁铁孔
// -------------------------
//
// glue       : 普通直孔，适合滴胶固定
// crush_ribs : Gridfinity 风格波浪压溃筋，磁铁压入后免胶固定
// snap_tabs  : 孔口保留几个圆钝小压片，磁铁压入后被上沿卡住
//
module magnet_socket_cut(
    magnet_diam = 8,
    magnet_depth = 3,
    fixing_mode = "crush_ribs",
    hole_slop = 0.08,
    rib_depth = 0.08,
    rib_count = 8,
    rib_resolution = 72,
    chamfer = 0.25,
    tab_count = 6,
    tab_depth = 0.22,
    tab_resolution = 96
){
    chamfer_h = min(chamfer, magnet_depth * 0.45);

    if (fixing_mode == "glue") {
        union() {
            translate([0, 0, -magnet_depth - 0.01])
                cylinder(
                    d = magnet_diam + hole_slop,
                    h = magnet_depth + 0.02
                );

            // 胶水孔也加入口倒角，方便放入磁铁和点胶。
            magnet_round_chamfer_cut(
                magnet_diam = magnet_diam,
                hole_slop = hole_slop,
                chamfer = chamfer,
                chamfer_h = chamfer_h
            );
        }
    }
    else if (fixing_mode == "crush_ribs") {
        hole_r = (magnet_diam + hole_slop) / 2;
        rib_inner_r = max(hole_r - rib_depth, 0.01);

        union() {
            // Gridfinity 风格波浪压溃筋。打印时内凸筋会被磁铁压溃，形成免胶摩擦固定。
            translate([0, 0, -magnet_depth - 0.01])
                linear_extrude(height = magnet_depth + 0.02)
                    crush_rib_profile(
                        outer_r = hole_r,
                        inner_r = rib_inner_r,
                        rib_count = rib_count,
                        resolution = rib_resolution
                    );

            // 入口倒角，方便磁铁找正并压入。
            magnet_round_chamfer_cut(
                magnet_diam = magnet_diam,
                hole_slop = hole_slop,
                chamfer = chamfer,
                chamfer_h = chamfer_h
            );
        }
    }
    else {
        hole_r = (magnet_diam + hole_slop) / 2;
        tab_chamfer_h = min(chamfer_h, magnet_depth * 0.45);
        tab_h = max(magnet_depth - tab_chamfer_h, 0.05);

        union() {
            // 压片从孔底延伸到倒角下方，和磁铁主体等高；倒角区保持纯圆。
            translate([0, 0, -magnet_depth - 0.01])
                linear_extrude(height = tab_h + 0.02)
                    snap_tab_profile(
                        hole_r = hole_r,
                        tab_depth = tab_depth,
                        tab_count = tab_count,
                        tab_resolution = tab_resolution
                    );

            // 入口是纯圆形倒角，不带压片齿形。
            magnet_round_chamfer_cut(
                magnet_diam = magnet_diam,
                hole_slop = hole_slop,
                chamfer = chamfer,
                chamfer_h = tab_chamfer_h
            );
        }
    }
}


function crush_rib_radius(a, outer_r, inner_r, rib_count) =
    let (
        wave_range = (outer_r - inner_r) / 2,
        wave_center = inner_r + wave_range
    )
    wave_center + sin(a * rib_count) * wave_range;


module crush_rib_profile(
    outer_r,
    inner_r,
    rib_count,
    resolution
){
    polygon(points=[
        for (i=[0:1:resolution - 1])
            let (
                a = 360 * i / resolution,
                r = crush_rib_radius(a, outer_r, inner_r, rib_count)
            )
            [r * cos(a), r * sin(a)]
    ]);
}


module magnet_round_chamfer_cut(
    magnet_diam = 8,
    hole_slop = 0.08,
    chamfer = 0.25,
    chamfer_h = 0.25
){
    if (chamfer_h > 0)
        translate([0, 0, -chamfer_h - 0.01])
            cylinder(
                d1 = magnet_diam + hole_slop,
                d2 = magnet_diam + hole_slop + chamfer * 2,
                h = chamfer_h + 0.02
            );
}


module snap_tab_profile(
    hole_r,
    tab_depth,
    tab_count,
    tab_resolution
){
    polygon(points=[
        for (i=[0:1:tab_resolution - 1])
            let (
                a = 360 * i / tab_resolution,
                sector = 360 / tab_count,
                local = abs(((a + sector / 2) % sector) - sector / 2),
                tab_half_angle = sector * 0.18,
                // 独立的圆钝短舌头，压片之间保留更长的圆孔段。
                tab = local < tab_half_angle
                    ? 0.5 + 0.5 * cos(180 * local / tab_half_angle)
                    : 0,
                r = hole_r - tab_depth * tab
            )
            [r * cos(a), r * sin(a)]
    ]);
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
    chamfer = 0.25,
    tab_count = 6,
    tab_depth = 0.22,
    tab_resolution = 96
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
                chamfer = chamfer,
                tab_count = tab_count,
                tab_depth = tab_depth,
                tab_resolution = tab_resolution
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
                chamfer = chamfer,
                tab_count = tab_count,
                tab_depth = tab_depth,
                tab_resolution = tab_resolution
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
                chamfer = chamfer,
                tab_count = tab_count,
                tab_depth = tab_depth,
                tab_resolution = tab_resolution
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
                chamfer = chamfer,
                tab_count = tab_count,
                tab_depth = tab_depth,
                tab_resolution = tab_resolution
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

// 磁铁固定方式："glue" 普通胶水孔，"crush_ribs" 压溃筋免胶固定，"snap_tabs" 上沿圆钝压片免胶固定
magnet_fixing_mode = "crush_ribs"; // [glue, crush_ribs, snap_tabs]

// 基础磁铁孔余量，越大越松
magnet_hole_slop = 0.12;         // [0:0.02:0.25]

// 压溃筋向孔内凸出的深度，越大越紧
magnet_rib_depth = 0.12;         // [0.02:0.02:0.18]

// 压溃筋数量
magnet_rib_count = 8;            // [6:1:12]

// 压溃筋圆周细分，数值越大越圆滑
magnet_rib_resolution = 96;      // [48:12:144]

// 磁铁孔入口倒角
magnet_chamfer = 0.25;           // [0:0.05:0.6]

// 上沿圆钝压片数量
magnet_tab_count = 8;            // [3:1:12]

// 上沿圆钝压片向孔内压住磁铁的深度，越大越紧
magnet_tab_depth = 0.15;         // [0.06:0.02:0.35]

// 上沿圆钝压片圆周细分，数值越大越圆滑
magnet_tab_resolution = 96;      // [48:12:144]


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
        chamfer = magnet_chamfer,
        tab_count = magnet_tab_count,
        tab_depth = magnet_tab_depth,
        tab_resolution = magnet_tab_resolution
    );
}
