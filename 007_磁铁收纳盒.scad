include <BOSL2/std.scad>

$fn = 148;

// 示例
box_width = 120;
box_height = 120;
box_depth = 120;
side_thick = 20;
bottom_wall_thick = 60;
ball_radius = 8;
ball_y_pos = 60;
socket_slop = 0.35;
insert_angle = 25;              // [0:10:180]


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


// 绕左右凸点旋转的内柱。
// pivot_y/pivot_z 是凸点轴线位置，尾端做成圆柱面，旋转时避免方角干涉。
// socket_r 是柱子上对应凸点的孔半径，留一点间隙后两者不会连成一体。
module rotating_insert(
    width = 115,
    length = 600,
    height = 115,
    pivot_y = 120,
    pivot_z = 60,
    tail_r = undef,
    socket_r = 8.4,
    angle = 0
) {
    end_r = is_undef(tail_r) ? height / 2 : tail_r;
    straight_len = max(0, length - end_r);

    translate([0, pivot_y, pivot_z])
        rotate([angle, 0, 0])
            difference() {
                rotate([0, 90, 0])
                    linear_extrude(height = width, convexity = 10)
                        union() {
                            // 直段从凸点轴线向前延伸。
                            translate([0, -height / 2])
                                square([straight_len, height]);

                            // 尾端为圆柱面，圆心落在凸点轴线上。
                            intersection() {
                                circle(r = end_r);
                                translate([-end_r, -height / 2])
                                    square([end_r, height]);
                            }
                        }

                // 与左右凸点同轴的旋转孔。
                translate([-0.5, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(r = socket_r, h = width + 1);
            }
}

u_part(
    width = box_width,
    height = box_height,
    thick = side_thick,
    bottom_thick = bottom_wall_thick,
    depth = box_depth,
    ball_r = ball_radius,
    ball_y = ball_y_pos
);

seg = 5;

translate([side_thick + seg / 2, 0, 0])
    rotating_insert(
        width = box_width - seg,
        length = 600,
        height = box_depth - seg,
        pivot_y = bottom_wall_thick + ball_y_pos,
        pivot_z = box_depth / 2,
        socket_r = ball_radius + socket_slop,
        angle = insert_angle
    );
