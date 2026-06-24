include <BOSL2/std.scad>

$fn = 96;

// 盒体参数
box_size = [60, 36];       // [30:100] 盒子外部长宽
box_h = 14;               // [6:30] 下半盒高度
lid_h = 6;                // [3:15] 上盖高度
wall = 2;                 // [1:0.5:5] 壁厚
rounding = 2;             // [0:0.5:6] 圆角

// 滑轨参数
rail_len = 44;            // [20:90] 滑轨长度
rail_w = 5;               // [2:0.5:10] 燕尾最大宽度
rail_neck = 3;            // [1:0.5:8] 燕尾根部宽度
rail_h = 3;               // [1:0.5:8] 滑轨高度
rail_z = 3;               // [1:0.5:10] 滑轨离盖底/盒口的高度
clearance = 0.35;         // [0.1:0.05:1] 装配间隙

// 示意图摆放参数
lid_lift = 18;            // [0:40] 上盖抬高距离
slide_offset = 14;        // [-30:30] 滑入方向错位

module dovetail_2d(max_w, neck_w, h) {
    polygon([
        [0, -neck_w / 2],
        [0,  neck_w / 2],
        [h,  max_w / 2],
        [h, -max_w / 2]
    ]);
}

// 沿 X 方向拉伸的燕尾条，截面在 Y/Z 平面。
module x_dovetail(len, max_w, neck_w, h) {
    rotate([0, 90, 0])
        linear_extrude(height = len, center = true)
            dovetail_2d(max_w, neck_w, h);
}

module lower_box() {
    difference() {
        rect_tube(size = box_size, wall = wall, h = box_h, rounding = rounding);

        // 两侧燕尾凹槽。槽比上盖凸轨略大，提供滑动间隙。
        for (side = [-1, 1]) {
            translate([
                0,
                side * (box_size[1] / 2 - wall - rail_h / 2),
                box_h - rail_z
            ])
                rotate([0, 0, side > 0 ? 0 : 180])
                    x_dovetail(
                        rail_len + clearance * 2,
                        rail_w + clearance * 2,
                        rail_neck + clearance * 2,
                        rail_h + clearance
                    );
        }
    }
}

module lid_with_rails() {
    union() {
        rect_tube(size = box_size, wall = wall, h = lid_h, rounding = rounding);

        // 上盖两侧凸轨，滑入下半盒的燕尾凹槽。
        for (side = [-1, 1]) {
            translate([
                0,
                side * (box_size[1] / 2 - wall - rail_h / 2),
                -rail_z
            ])
                rotate([0, 0, side > 0 ? 0 : 180])
                    color("red")
                        x_dovetail(rail_len, rail_w, rail_neck, rail_h);
        }

        // 前端挡块：滑到底时定位，示意用。
        translate([rail_len / 2 + wall / 2, 0, -rail_z + rail_h / 2])
            color("orange")
                cuboid([wall, box_size[1] - wall * 4, rail_h], rounding = 0.3);
    }
}

// 下半盒
color("lightgray")
    lower_box();

// 上盖抬起并沿 X 方向错开，展示滑轨如何啮合。
translate([slide_offset, 0, box_h + lid_lift])
    color("white")
        lid_with_rails();

