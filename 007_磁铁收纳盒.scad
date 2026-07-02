include <BOSL2/std.scad>

$fn = 148;

// ---------------- 参数 ----------------

// 显示模式
view_mode = "外架透明";          // [装配, 外架透明, 分解查看, 只看外架, 只看柱子]

// 内部框宽度
box_width = 12;                  // [8:0.5:40]

// 内部框高度
box_height = 12;                 // [8:0.5:40]

// 内部框深度
box_depth = 12;                  // [8:0.5:40]

// 左右两侧壁厚
side_thick = 2.4;                // [1.6:0.1:5]

// 底边壁厚
bottom_wall_thick = 6;           // [2:0.5:10]

// 左右凸点半径
ball_radius = 1.4;               // [0.8:0.1:3]

// 凸点嵌入侧壁的深度，避免切片时只贴面不相连
ball_overlap = 0.2;              // [0:0.02:0.3]

// 凸点中心离内部底面的高度
ball_y_pos = 6;                  // [2:0.5:10]

// 柱子和内部框之间的装配间隙
insert_clearance = 0.8;          // [0.4:0.1:2]

// 分解查看时两个零件拉开的距离
explode_gap = 8;                 // [4:1:30]

// 柱子从凸点轴线向前伸出的长度
insert_length = 48;              // [20:2:80]

// 柱子旋转孔相对凸点半径的放大间隙
socket_slop = 0.3;               // [0.15:0.05:0.8]

// 柱子绕左右凸点轴线旋转的角度
insert_angle = 90;               // [90:10:180]


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
    ball_y = 40,
    ball_overlap = 0.05
) {
    bottom_wall_thick = is_undef(bottom_thick) ? thick : bottom_thick;
    outer_width = width + 2 * thick;
    outer_height = height + bottom_wall_thick;
    ball_neck_r = ball_r * 0.65;
    ball_neck_back = 0.25;
    ball_neck_len = ball_overlap + ball_neck_back;

    union() {
        // 左边壁
        cube([thick, outer_height, depth]);

        // 右边壁
        translate([thick + width, 0, 0])
            cube([thick, outer_height, depth]);

        // 底边壁
        cube([outer_width, bottom_wall_thick, depth]);

        // 左凸点根部，增强凸点和侧壁的连接。
        translate([thick - ball_overlap - 0.02, bottom_wall_thick + ball_y, depth/2])
            rotate([0, 90, 0])
                cylinder(r = ball_neck_r, h = ball_neck_len);

        // 左内壁半球，贴在 x = thick 表面，朝内凸起
        translate([thick - ball_overlap, bottom_wall_thick + ball_y, depth/2])
            half_sphere_x_pos(ball_r);

        // 右凸点根部，增强凸点和侧壁的连接。
        translate([thick + width - ball_neck_back, bottom_wall_thick + ball_y, depth/2])
            rotate([0, 90, 0])
                cylinder(r = ball_neck_r, h = ball_neck_len);

        // 右内壁半球，贴在 x = thick + width 表面，朝内凸起
        translate([thick + width + ball_overlap, bottom_wall_thick + ball_y, depth/2])
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

                            // 凸点孔周围保留完整圆环，避免孔把柱子切成上下两半。
                            circle(r = end_r);
                        }

                // 与左右凸点同轴的旋转孔。
                translate([-0.5, 0, 0])
                    rotate([0, 90, 0])
                        cylinder(r = socket_r, h = width + 1);
            }
}


module outer_frame_part() {
    u_part(
        width = box_width,
        height = box_height,
        thick = side_thick,
        bottom_thick = bottom_wall_thick,
        depth = box_depth,
        ball_r = ball_radius,
        ball_y = ball_y_pos,
        ball_overlap = ball_overlap
    );
}


module inner_insert_part() {
    translate([side_thick + insert_clearance / 2, 0, 0])
        rotating_insert(
            width = box_width - insert_clearance,
            length = insert_length,
            height = box_depth - insert_clearance,
            pivot_y = bottom_wall_thick + ball_y_pos,
            pivot_z = box_depth / 2,
            socket_r = ball_radius + socket_slop,
            angle = insert_angle
        );
}


module show_model() {
    if (view_mode == "只看外架") {
        outer_frame_part();
    } else if (view_mode == "只看柱子") {
        inner_insert_part();
    } else if (view_mode == "分解查看") {
        translate([-explode_gap, 0, 0])
            outer_frame_part();
        translate([explode_gap, 0, 0])
            inner_insert_part();
    } else if (view_mode == "外架透明") {
        color([0.2, 0.55, 0.95, 0.28])
            outer_frame_part();
        color([1, 0.72, 0.18, 1])
            inner_insert_part();
    } else {
        outer_frame_part();
        inner_insert_part();
    }
}


show_model();
