include <BOSL2/std.scad>

$fn = 64;

wall = 2;
bottom_t = 2;
size = [100, 80];
height = 40;
rounding = 5;



// 底板
cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=[0,0,1]);

// 盒子侧壁
rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding);
