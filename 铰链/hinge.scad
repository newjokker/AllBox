include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
$fn=64;


thickness=2;
seg_gap = 0.2;
end_space = 0.2;
ang=0;
module myhinge(inner)
   knuckle_hinge(length=25, segs=13,offset=thickness/2+end_space, inner=inner, clearance=-thickness/2, knuckle_diam=thickness,
                 arm_angle=45, gap=seg_gap, in_place=true, clip=thickness/2, )
                 children();

module leaf() cuboid([25,thickness,25],anchor=TOP+BACK, rounding=7, edges=[BOT+LEFT,BOT+RIGHT]);

xrot(90)
  myhinge(true){
    position(BOT) leaf();
    color("lightblue")
      up(end_space) attach(BOT,TOP,inside=true)
      tag("")  // cancel default "remove" tag
      xrot(-ang,cp=[0,-thickness/2,thickness/2]) myhinge(false)
        position(BOT) leaf();
  }



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

translate([0, 0, 60]) 
    box_down_1(size=[50, 40], height=25, wall=2);


