include <BOSL2/std.scad>
include <BOSL2/joiners.scad>
cuboid([25,15,5],anchor=BOTTOM)
    attach(BACK)rabbit_clip("pin", length=25, width=25, thickness=1.5, snap=2, compression=0, lock=true, depth=5, lock_clearance=3);
left(32)
diff("remove")
cuboid([30,30,11],orient=BACK,anchor=BACK){
    tag("remove")attach(BACK)rabbit_clip("socket", length=25, width=25, thickness=1.5, snap=2, compression=0, lock=true, depth=5.5, lock_clearance=3);
    xflip_copy()
      position(FRONT+LEFT)
      xscale(0.8)
      tag("remove")zcyl(l=20,r=13.5, $fn=64);
}