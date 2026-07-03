include <BOSL2/std.scad>

$fn = 256;

h = 75;

thick = 2;

difference(){
    cylinder(r=20, h=h);
    translate([0, 0, thick])
        cylinder(r=11, h=h);

    translate([17.5, 0, thick])
        cylinder(r=3.15, h=h);

}

