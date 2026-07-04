include <BOSL2/std.scad>

$fn = 148;


module A(h, r){

    difference(){

        cuboid([6,4.6,h], anchor=[0,0,-1]);
        // cylinder(r=4, h=h, center=false);
        
        translate([0, 0.5, 3])
            cylinder(r=2.15, h=h, center=false);

        translate([0, 0.5, 1])
            cylinder(r=1.15, h=h, center=false);
    }
}

A(20, 2);
