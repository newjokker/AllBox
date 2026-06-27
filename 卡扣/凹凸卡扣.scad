include <BOSL2/std.scad>

$fn = 96;

// 摩擦凸点, 用于盒子上下盖子连接
module FrictionBump(length, r){

    difference() {
        rotate([90, 0, 0]){
            cylinder(h=length, r=r, center=true);

            translate([0, 0, length/2]) 
                sphere(r = r);

            translate([0, 0, -length/2]) 
                sphere(r = r);
        }

        cuboid(size=[2*r, length + 2*r, 2*r], anchor=[1, 0, 0]);
    }
}


FrictionBump(10, 5);