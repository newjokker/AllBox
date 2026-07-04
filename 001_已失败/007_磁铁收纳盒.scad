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
bottom_wall_thick = 8;           // [2:0.5:10]

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
insert_length = 80;              // [20:2:80]

// 柱子旋转孔相对凸点半径的放大间隙
socket_slop = 0.3;               // [0.15:0.05:0.8]

// 柱子绕左右凸点轴线旋转的角度
insert_angle = 90;               // [90:10:180]

// 柱子圆柱底面到磁铁位之间保留的实体厚度
insert_hole_bottom_keep = 1;      // [0.4:0.1:4]

// 底部小圆柱磁铁位长度
insert_magnet_pocket_len = 2;     // [0.8:0.1:8]

// 底部小圆柱磁铁位半径
insert_magnet_pocket_r = 2;    // [0.6:0.05:3]

// 从磁铁位往顶部贯通的大孔半径
insert_through_hole_r = 4.5;     // [1:0.05:5]

// 柱子上表面削掉的厚度，用来露出中间孔
insert_top_window_depth = 2.0;    // [0:0.1:8]

// 只看柱子时，沿柱子宽度中心剖开的比例
insert_preview_cut_ratio = 0.5;   // [0.1:0.05:1]


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


// 从当前高度沿 -Z 方向向下挖圆柱孔。
module cylinder_down(r, h) {
    rotate([180, 0, 0])
        cylinder(r = r, h = h);
}


// U 型结构 + 两个内侧半球。
// width/height/depth 表示内部框尺寸，内部空间固定在：
// X: 0..width, Y: 0..height, Z: 0..depth。
// thick 和 bottom_thick 都向内部空间外侧扩展。
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
    ball_neck_r = ball_r * 0.65;
    ball_neck_back = 0.25;
    ball_neck_len = ball_overlap + ball_neck_back;

    union() {
        // 左边壁，从内部空间 x=0 向外扩展。
        translate([-thick, -bottom_wall_thick, 0])
            cube([thick, height + bottom_wall_thick, depth]);

        // 右边壁，从内部空间 x=width 向外扩展。
        translate([width, -bottom_wall_thick, 0])
            cube([thick, height + bottom_wall_thick, depth]);

        // 底边壁，从内部空间 y=0 向外扩展。
        translate([-thick, -bottom_wall_thick, 0])
            cube([width + 2 * thick, bottom_wall_thick, depth]);

        // 左凸点根部，增强凸点和侧壁的连接。
        translate([-ball_overlap - ball_neck_back, ball_y, depth/2])
            rotate([0, 90, 0])
                cylinder(r = ball_neck_r, h = ball_neck_len);

        // 左内壁半球，贴在内部空间 x=0 表面，朝内凸起。
        translate([-ball_overlap, ball_y, depth/2])
            half_sphere_x_pos(ball_r);

        // 右凸点根部，增强凸点和侧壁的连接。
        translate([width - 0.02, ball_y, depth/2])
            rotate([0, 90, 0])
                cylinder(r = ball_neck_r, h = ball_neck_len);

        // 右内壁半球，贴在内部空间 x=width 表面，朝内凸起。
        translate([width + ball_overlap, ball_y, depth/2])
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
    bottom_keep = 1,
    magnet_pocket_len = 2,
    magnet_pocket_r = 1.15,
    through_hole_r = 2.15,
    top_window_depth = 0,
    preview_cut = false,
    preview_cut_ratio = 0.5,
    angle = 0
) {
    end_r = is_undef(tail_r) ? height / 2 : tail_r;
    straight_len = max(0, length - end_r);
    hole_center_x = width / 2;
    hole_eps = 0.05;
    pocket_len = min(magnet_pocket_len, max(0, straight_len - bottom_keep));
    through_len = max(0, straight_len - bottom_keep - pocket_len);
    magnet_pocket_top_z = -bottom_keep;
    through_hole_top_z = magnet_pocket_top_z - pocket_len;
    window_depth = min(max(0, top_window_depth), height);
    cut_ratio = min(max(preview_cut_ratio, 0), 1);
    cut_width = width * cut_ratio + 2;

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

                // 小磁铁位先整体抬升一个磁铁厚度，再从该高度向下挖。
                translate([hole_center_x, 0, magnet_pocket_top_z])
                    cylinder_down(r = magnet_pocket_r, h = pocket_len + hole_eps);

                if (through_len > 0)
                    translate([hole_center_x, 0, -straight_len - hole_eps])
                        cylinder(r = through_hole_r, h = through_hole_top_z + straight_len + 2 * hole_eps);

                if (window_depth > 0)
                    translate([-1, height / 2 - window_depth, -straight_len - end_r - 1])
                        cube([width + 2, window_depth + end_r + 1, straight_len + 2 * end_r + 2]);

                if (preview_cut)
                    translate([width - cut_width + 1, -height - 1, -straight_len - end_r - 1])
                        cube([cut_width, 2 * height + 2, straight_len + 2 * end_r + 2]);
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
    translate([insert_clearance / 2, 0, 0])
        rotating_insert(
            width = box_width - insert_clearance,
            length = insert_length,
            height = box_depth - insert_clearance,
            pivot_y = ball_y_pos,
            pivot_z = box_depth / 2,
            socket_r = ball_radius + socket_slop,
            bottom_keep = insert_hole_bottom_keep,
            magnet_pocket_len = insert_magnet_pocket_len,
            magnet_pocket_r = insert_magnet_pocket_r,
            through_hole_r = insert_through_hole_r,
            top_window_depth = insert_top_window_depth,
            angle = insert_angle
        );
}


module inner_insert_preview_cut_part() {
    translate([insert_clearance / 2, 0, 0])
        rotating_insert(
            width = box_width - insert_clearance,
            length = insert_length,
            height = box_depth - insert_clearance,
            pivot_y = ball_y_pos,
            pivot_z = box_depth / 2,
            socket_r = ball_radius + socket_slop,
            bottom_keep = insert_hole_bottom_keep,
            magnet_pocket_len = insert_magnet_pocket_len,
            magnet_pocket_r = insert_magnet_pocket_r,
            through_hole_r = insert_through_hole_r,
            top_window_depth = insert_top_window_depth,
            preview_cut = true,
            preview_cut_ratio = insert_preview_cut_ratio,
            angle = insert_angle
        );
}


module show_model() {
    if (view_mode == "只看外架") {
        outer_frame_part();
    } else if (view_mode == "只看柱子") {
        inner_insert_preview_cut_part();
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
