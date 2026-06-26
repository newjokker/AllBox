include <BOSL2/std.scad>

$fn = 64;


module box_down_1(wall=1, bottom_t=2, size=[100, 80], height=40, rounding=5){

    // 底板
    cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=[0,0,1]);

    // 盒子侧壁
    rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding);

}

// 唇边
module box_lip(){
    
}


box_down_1(size=[50, 40], height=20, wall=1);

