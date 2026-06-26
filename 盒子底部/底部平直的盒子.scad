include <BOSL2/std.scad>

$fn = 64;


module box_down_1(wall=2, bottom_t=2, size=[100, 80], height=40, rounding=5, lip_height=2){

    // 底板
    cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=[0,0,1]);

    // 盒子侧壁
    rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding);

    // 唇边
    // 突出来的
    color("red") 
    # translate([0, 0, height - bottom_t]) 
        rect_tube(size = [size.x-wall, size.y-wall], wall = wall/2, h = lip_height, rounding = rounding-wall/2);

}

box_down_1(size=[50, 40], height=20, wall=3, lip_height=1, rounding=5);

