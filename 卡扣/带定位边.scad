include <BOSL2/std.scad>

$fn = 96;

// 上半盒：定位边直接连在盖子下面。
translate([0, 0, 15])
    union() {
        rect_tube(size = [30, 30], wall = 1, h = 5, rounding = 2);

        translate([0, 0, -1])
            color("red")
                rect_tube(size = [27, 27], wall = 1, h = 2, rounding = 1.5);
    }

// 下半盒：定位边插入内侧，用盒壁内口完成定位。
rect_tube(size = [30, 30], wall = 1, h = 5, rounding = 2);
