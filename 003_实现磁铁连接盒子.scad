include <BOSL2/std.scad>

$fn = 64;


// 盒子圆角内侧的三角锥磁铁座
// leg_len      : 直角边长度
// mount_height : 三角锥高度
// magnet_diam  : 磁铁直径
// magnet_depth : 磁铁孔深度
// box_corner_r : 盒子圆角半径
module corner_magnet_mount(
    leg_len = 40,
    mount_height = 30,
    magnet_diam = 8,
    magnet_depth = 3,
    box_corner_r = 5
){

    // 磁铁孔中心位置
    // 位于原始等腰直角三角形底面的内心位置
    magnet_center_offset = leg_len * (2 - sqrt(2)) / 2;

    // 三角锥四个顶点
    pyramid_points = [
        [0, 0, 0],                     // 0: 盒子内角顶点
        [leg_len, 0, 0],               // 1: X 方向底边端点
        [0, leg_len, 0],               // 2: Y 方向底边端点
        [0, 0, -mount_height]          // 3: 向下的锥顶
    ];

    // 三角锥四个面
    pyramid_faces = [
        [0, 2, 1],     // 顶面：等腰直角三角形
        [0, 1, 3],     // X-Z 侧面
        [0, 3, 2],     // Y-Z 侧面
        [1, 2, 3]      // 斜面
    ];

    difference(){

        intersection(){

            // 原始三角锥磁铁座
            polyhedron(
                points = pyramid_points,
                faces = pyramid_faces
            );

            // 只裁剪靠近盒子圆角的那个角
            // 用一个带单个 R 角的矩形柱模拟盒子的圆角边界
            translate([leg_len / 2, leg_len / 2, -mount_height / 2])
                cuboid(
                    [leg_len, leg_len, mount_height + 0.02],
                    rounding = box_corner_r,
                    edges = [FRONT + LEFT],
                    anchor = CENTER
                );
        }

        // 磁铁沉孔
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


// 示例
corner_magnet_mount(
    leg_len = 40,
    mount_height = 30,
    magnet_diam = 8,
    magnet_depth = 3,
    box_corner_r = 13
);