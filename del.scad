include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
include <盒子底部/底部平直的盒子.scad>

$fn = 128;

// -------------------------
// 角落磁铁座
// -------------------------
//
// leg_len       : 磁铁座直角边长度
// holder_height : 磁铁座向下延伸的高度
// magnet_diam   : 磁铁直径
// magnet_depth  : 磁铁孔深度
// fixing_mode   : glue 为普通胶水孔，crush_ribs 为压溃筋免胶固定
// corner_r      : 对应盒子圆角半径
// holder_shape  : "pyramid" 为三角锥，"prism" 为三角柱
//
module corner_magnet_holder(
    leg_len = 25,
    holder_height = 20,
    magnet_diam = 8,
    magnet_depth = 3,
    corner_r = 5,
    holder_shape = "pyramid",   // "pyramid" / "prism"
    fixing_mode = "crush_ribs",
    hole_slop = 0.08,
    rib_depth = 0.08,
    rib_count = 8,
    rib_resolution = 72,
    chamfer = 0.25
){
    // 磁铁中心：等腰直角三角形底面的内心
    magnet_center_offset = leg_len * (2 - sqrt(2)) / 2;

    // 三角锥顶点
    pyramid_points = [
        [0, 0, 0],
        [leg_len, 0, 0],
        [0, leg_len, 0],
        [0, 0, -holder_height]
    ];

    // 三角锥面
    pyramid_faces = [
        [0, 2, 1],
        [0, 1, 3],
        [0, 3, 2],
        [1, 2, 3]
    ];

    // 三角柱顶点
    prism_points = [
        // 上三角面 z = 0
        [0, 0, 0],
        [leg_len, 0, 0],
        [0, leg_len, 0],

        // 下三角面 z = -holder_height
        [0, 0, -holder_height],
        [leg_len, 0, -holder_height],
        [0, leg_len, -holder_height]
    ];

    // 三角柱面
    prism_faces = [
        [0, 2, 1],      // 上面
        [3, 4, 5],      // 下面

        [0, 1, 4, 3],   // X 方向侧面
        [1, 2, 5, 4],   // 斜侧面
        [2, 0, 3, 5]    // Y 方向侧面
    ];

    assert(
        holder_shape == "pyramid" || holder_shape == "prism",
        str("holder_shape must be \"pyramid\" or \"prism\", got: ", holder_shape)
    );

    holder_points = holder_shape == "pyramid" ? pyramid_points : prism_points;
    holder_faces  = holder_shape == "pyramid" ? pyramid_faces  : prism_faces;

    difference(){

        intersection(){

            // 原始三角锥 / 三角柱
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

        // // 磁铁孔
        // translate([
        //     magnet_center_offset,
        //     magnet_center_offset,
        //     0
        // ])
        //     magnet_socket_cut(
        //         magnet_diam = magnet_diam,
        //         magnet_depth = magnet_depth,
        //         fixing_mode = fixing_mode,
        //         hole_slop = hole_slop,
        //         rib_depth = rib_depth,
        //         rib_count = rib_count,
        //         rib_resolution = rib_resolution,
        //         chamfer = chamfer
        //     );
    }
}

translate([50, 0, 0])
    corner_magnet_holder();



cuboid([25, 25, 20], rounding=5, edges = [FRONT + LEFT], anchor = CENTER);

translate([-25/2 + 5, -25/2 + 5, 0])
    color("red")
        cylinder(r=5, h=21, center=true);

