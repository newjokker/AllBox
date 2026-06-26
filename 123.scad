include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
$fn = 64;
diam = 2;       // Hinge knuckle diameter
seg_gap = 0.15; // Gap between hinge segments
clear = 0.35;   // 两个合叶之间的距离
ang=180;          // Hinge rotation angle
wall = 1.2;       // Box wall thickness
hinge_mount = 4;  // Keep a wider solid strip only where the hinge connects
box_gap = 0;    // Extra distance between the two boxes
module myhinge(inner)
   knuckle_hinge(length=25, segs=11,offset=1.2, inner=inner, clearance=clear, knuckle_diam=diam,
                 pin_diam=diam-0.2, arm_height=hinge_mount, arm_angle=28, gap=seg_gap,
                 in_place=true, anchor=CTR,clip=2+clear)
      children();
module leaf()
  difference() {
    cuboid([25,20,12], anchor=TOP+BACK, edges=[BOT+LEFT,BOT+RIGHT]);
    fwd(hinge_mount)
      down(-wall)
        cuboid([25-2*wall, 20-2*wall, 12], anchor=TOP+BACK);
  }
xrot(90){    // Rotate to printing orientation
  myhinge(true) position(BOT) leaf();
  color("lightblue")
    back(box_gap)
    xrot(180-ang,cp=[0,clear+box_gap,0])
    zrot(180,cp=[0,clear+box_gap,0])
    myhinge(false) position(BOT) leaf();
}
