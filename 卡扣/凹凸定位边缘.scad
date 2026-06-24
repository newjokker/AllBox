include <BOSL2/std.scad>

$fn = 96;


// 卡扣的半部分
translate([0, 0, 15])
    union(){
        rect_tube(size = [30, 30], wall=1, h=5, rounding=2);
        translate([0, 0, -2])
        color("red")
            rect_tube(size = [30, 30], wall=0.5, h=2, rounding=2);
    }

// 卡扣的下半部分
difference(){
    rect_tube(size = [30, 30], wall=1, h=5, rounding=2);
    translate([0, 0, 5-2])
        rect_tube(size = [30, 30], wall=0.5, h=2, rounding=2);
}

