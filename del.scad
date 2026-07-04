include <BOSL2/std.scad>

$fn = 256;         


h = 11;

difference(){
    
    cylinder(r=43/2, h=h);
    
    translate([0, 0, 1.5])
        cylinder(r=41/2, h=h);
    
    translate([20.5, 0, -0.01])
        cuboid([3, 3, h + 0.02], anchor=[0, 0, -1]);
    
    translate([18, 0, -0.01])
        cylinder(r=4, h=h+2);

}

cylinder(r=21.9/2, h=h);





