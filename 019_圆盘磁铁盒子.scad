include <BOSL2/std.scad>

$fn = 256;

h = 75;

thick = 2;
outer_radius = 20;
hole_count = 8;
hole_angle_step = 24;
hole_radius_6mm = 3.15;
hole_radius_5mm = 2.65;
hole_center_radius_6mm = 17.6;
hole_5mm_start_angle = hole_count * hole_angle_step;
hole_5mm_center_radius = 18;

difference(){
    cylinder(r=outer_radius, h=h);
    translate([0, 0, thick])
        cylinder(r=11, h=h);

    // 6mm 磁铁
    for (i = [0:hole_count - 1]) {
        rotate([0, 0, i * hole_angle_step])
            translate([hole_center_radius_6mm, 0, thick])
                cylinder(r=hole_radius_6mm, h=h);
    }

    // 5mm 磁铁
    for (i = [0:hole_count - 1]) {
        rotate([0, 0, hole_5mm_start_angle + i * hole_angle_step])
            translate([hole_5mm_center_radius, 0, thick])
                cylinder(r=hole_radius_5mm, h=h);
    }
}
