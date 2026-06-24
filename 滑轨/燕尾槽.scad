include <BOSL2/std.scad>
include <BOSL2/joiners.scad>

cuboid([50,30,10])
  attach(TOP) 
    dovetail("male", slide=50, width=18, height=4, back_width=15, spin=90);

fwd(35)
  diff("remove")
    cuboid([50,30,10])
      tag("remove") attach(TOP) 
        dovetail("female", slide=150, width=18, height=4, back_width=15, spin=90, $slop=0.3);

