include <BOSL2/std.scad>

$fn = 96;

major = [80,60];   // 外形尺寸
corner_r = 10;     // 四角R
tube_r = 1.5;        // 截面半径

// 圆形截面
shape = circle(r=tube_r);

// 圆角矩形路径
path = round_corners(
    square(major, center=true),
    radius=corner_r,
    closed=true
);


path_sweep(shape, path, closed=true);

// translate([0, 0, -5])
//     rect_tube(size = [major.x + tube_r*2, major.y+ tube_r*2], wall = tube_r, h = 10, rounding = corner_r + tube_r);
