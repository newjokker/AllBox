length = 100;
width = 50;
height = 20;
r = 5;
d_w = 5;
d_l = 2;
out = [length-2*r, width-2*r, height/2-1];
in = [length-2*d_l-2*r,width-2*d_w-2*r,height/2-d_l-1];
$fn=100;
//rechte Hälfte
difference() {
    translate([-length/2+r,r+0.5,-height/2]) {
        minkowski(){
        cube(out, center=false);
        cylinder(1, r,r);
        }
        }
    translate([-(length-2*d_l-2*r)/2,d_w+0.5+r,-height/2+d_l+1]) {
        minkowski(){
        cube(in);
        cylinder(1, r,r);
        }
        }
        translate([length/4+14.0/2,0,0]) rotate([0,90,0]) cylinder(2.8,4.6,4.6);
        translate([length/4-14.0/2-2.8,0,0]) rotate([0,90,0]) cylinder(2.8,4.6,4.6);
        translate([length/4-14.4/2,0,0]) rotate([0,90,0]) cylinder(14.4,2.5,2.5);
        mirror([1,0,0]){
        translate([length/4+14.0/2,0,0]) rotate([0,90,0]) cylinder(2.8,4.6,4.6);
        translate([length/4-14.0/2-2.8,0,0]) rotate([0,90,0]) cylinder(2.8,4.6,4.6);
        translate([length/4-14.4/2,0,0]) rotate([0,90,0]) cylinder(14.4,2.5,2.5);
        }
        //Klipp female
        translate([-6,width+0.5,-5]) sphere(r=1.5);
        translate([6,width+0.5,-5]) sphere(r=1.5);
        translate([-6,width+0.5,-5]) rotate([0,90,0]) cylinder(12,1.5,1.5);
        translate([-7.5,width+0.5,-1.5]) rotate([45,0,0]) cube([15,2,2]);
}
//linke Hälfte
difference() {
    translate([-length/2+r,-0.5-width+r,-height/2]) {
        minkowski(){
        cube(out, center =false);
        cylinder(1, r,r);
        }
        }
        translate([-(length-2*d_l-2*r)/2,-(width-2*d_w)-0.5-d_w+r,-height/2+d_l+1]) {
        minkowski(){
        cube(in);
        cylinder(1, r,r);
        }
        }
        translate([length/4-14.8/2,0,0]) rotate([0,90,0]) cylinder(14.8,4.6,4.6);
        mirror([1,0,0]){
        translate([length/4-14.8/2,0,0]) rotate([0,90,0]) cylinder(14.8,4.6,4.6);
        }
        
}


//Scharniere
difference() {
translate([length/4-14/2,0,0]) rotate([0,90,0]) cylinder(14,4.0,4.0);
translate([length/4-14/2,0,0]) rotate([0,90,0]) cylinder(14,2.5,2.5);
}
translate([length/4-14.8/2,0,0]) rotate([0,90,0]) cylinder(14.8,2.3,2.3);
translate([length/4-14.0/2-2.4,0,0]) rotate([0,90,0]) cylinder(2,4.0,4.0);
translate([length/4+14.0/2+0.4,0,0]) rotate([0,90,0]) cylinder(2,4.0,4.0);
mirror([1,0,0]){
difference() {
translate([length/4-14/2,0,0]) rotate([0,90,0]) cylinder(14,4.0,4.0);
translate([length/4-14/2,0,0]) rotate([0,90,0]) cylinder(14,2.5,2.5);
}
translate([length/4-14.8/2,0,0]) rotate([0,90,0]) cylinder(14.8,2.3,2.3);
translate([length/4-14.0/2-2.4,0,0]) rotate([0,90,0]) cylinder(2,4.0,4.0);
translate([length/4+14.0/2+0.4,0,0]) rotate([0,90,0]) cylinder(2,4.0,4.0);
}
//Klipp Male
translate([-10,-width-2.49,-5]) cube([20,2,11]);
translate([-5,-width-0.49,5]) rotate([0,90,0]) cylinder(10,1,1);
