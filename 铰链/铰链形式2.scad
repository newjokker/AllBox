include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
$fn = 64;
diam = 2;       // Hinge knuckle diameter
seg_gap = 0.15; // Gap between hinge segments
clear = 0.15;   // Clearance so hinge will close all the way
ang=0;          // Hinge rotation angle
module myhinge(inner)
   knuckle_hinge(length=25, segs=11,offset=1.2, inner=inner, clearance=clear, knuckle_diam=diam,
                 pin_diam=diam-0.2, arm_angle=28, gap=seg_gap, in_place=true, anchor=CTR,clip=2+clear)
      children();
module leaf() cuboid([25,2,12],anchor=TOP+BACK,rounding=7,edges=[BOT+LEFT,BOT+RIGHT]);
xrot(90){    // Rotate to printing orientation
  myhinge(true) position(BOT) leaf();
  color("lightblue")
    xrot(180-ang,cp=[0,clear,0])
    zrot(180,cp=[0,clear,0])
    myhinge(false) position(BOT) leaf();
}