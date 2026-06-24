include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
$fn=32;
cuboid([2,40,15]){
  position(TOP+RIGHT) orient(anchor=RIGHT)
    # knuckle_hinge(length=35, segs=9, offset=3, arm_height=1,
          seg_ratio=1/3,in_place = true);
  attach(TOP,TOP) color("green")
    cuboid([2,40,15],anchor=TOP)
      position(TOP+LEFT) orient(anchor=LEFT)
        knuckle_hinge(length=35, segs=9, offset=3, arm_height=1,
              seg_ratio=1/3, inner=true, in_place = true);
 }