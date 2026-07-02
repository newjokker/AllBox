include <BOSL2/std.scad>

$fn = 148;

// 保留 X 正方向半球：平面在 x=0，凸起朝 +X
module half_sphere_x_pos(r) {
    intersection() {
        sphere(r);
        translate([0, -r, -r])
            cube([r, 2*r, 2*r]);
    }
}


// 保留 X 负方向半球：平面在 x=0，凸起朝 -X
module half_sphere_x_neg(r) {
    intersection() {
        sphere(r);
        translate([-r, -r, -r])
            cube([r, 2*r, 2*r]);
    }
}


// U 型结构 + 两个内侧半球
// width/height/depth 表示内部框尺寸。
// thick 控制左右壁厚，bottom_thick 控制底边厚度。
module u_part(
    width = 120,
    height = 80,
    thick = 8,
    bottom_thick = undef,
    depth = 20,
    ball_r = 10,
    ball_y = 40
) {
    bottom_wall_thick = is_undef(bottom_thick) ? thick : bottom_thick;
    outer_width = width + 2 * thick;
    outer_height = height + bottom_wall_thick;

    union() {
        // 左边壁
        cube([thick, outer_height, depth]);

        // 右边壁
        translate([thick + width, 0, 0])
            cube([thick, outer_height, depth]);

        // 底边壁
        cube([outer_width, bottom_wall_thick, depth]);

        // 左内壁半球，贴在 x = thick 表面，朝内凸起
        translate([thick, bottom_wall_thick + ball_y, depth/2])
            half_sphere_x_pos(ball_r);

        // 右内壁半球，贴在 x = thick + width 表面，朝内凸起
        translate([thick + width, bottom_wall_thick + ball_y, depth/2])
            half_sphere_x_neg(ball_r);
    }
}


// 示例
u_part(
    width = 120,
    height = 120,
    thick = 20,
    bottom_thick = 60,
    depth = 120,
    ball_r = 8,
    ball_y = 60
);

seg = 5;

translate([20 + seg/2, 60 + seg/2, 0]) 
    cuboid(size=[120 - seg, 600, 120 - seg], anchor=[-1, -1, -1]);

