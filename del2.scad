include <BOSL2/std.scad>

$fn = 64;

box_size = 25;
box_h = 20;

corner_r = 5;
small_r = 3;

edge_x = -box_size / 2;
edge_y = -box_size / 2;

big_x = edge_x + corner_r;
big_y = edge_y + corner_r;

tangent_dist = corner_r + small_r;


// 贴左边的小圆
small1_x = edge_x + small_r;
small1_y = big_y + sqrt(
    tangent_dist * tangent_dist
    - (small1_x - big_x) * (small1_x - big_x)
);


// 贴前边的小圆
small2_y = edge_y + small_r;
small2_x = big_x + sqrt(
    tangent_dist * tangent_dist
    - (small2_y - big_y) * (small2_y - big_y)
);


cuboid(
    [box_size, box_size, box_h],
    rounding = corner_r,
    edges = [FRONT + LEFT],
    anchor = CENTER
);


// 大圆柱
translate([big_x, big_y, 0])
    color("red")
        cylinder(r = corner_r, h = box_h + 1, center = true);


// 小圆柱 1：与左边和大圆相切
translate([small1_x, small1_y, 0])
    color("blue")
        cylinder(r = small_r, h = box_h + 1, center = true);


// 小圆柱 2：与前边和大圆相切
translate([small2_x, small2_y, 0])
    color("green")
        cylinder(r = small_r, h = box_h + 1, center = true);