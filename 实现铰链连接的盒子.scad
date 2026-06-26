include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn = 64;


// ---------------- 参数 ----------------
box_size = [42, 40, 15];
hinge_offset = 2.5;
open_angle = 180;
wall_thickness = 1;

// 铰链轴心距离盒子中心的 X 距离
hinge_axis_x = box_size.x / 2 + hinge_offset;


// ---------------- 空心盒体模块 ----------------
module A(anchor=CENTER, spin=0, orient=UP) {
    size = box_size;

    attachable(anchor, spin, orient, size=size) {
        difference() {
            cuboid(size, anchor=CENTER);

            translate([0, 0, 0.5])
                cuboid([box_size.x-2*wall_thickness, box_size.y-2*wall_thickness, box_size.z-wall_thickness], anchor=CENTER);
        }

        children();
    }
}


// ---------------- 主体 ----------------
// 先把下半盒的铰链轴移动到全局 Y 轴
translate([-hinge_axis_x, 0, 0]) 
{
    // 下半盒体
    A(anchor=TOP) {

        // 下半盒铰链
        position(TOP + RIGHT)
            orient(anchor=RIGHT)
                knuckle_hinge(
                    length=35,
                    segs=9,
                    offset=hinge_offset,
                    arm_height=1,
                    seg_ratio=1,
                    in_place=true
                );

        // 上半盒体
        attach(TOP, TOP) {

            // 注意：旋转要放在 attach 里面
            // 这样是先连接到正确位置，再绕铰链轴旋转
            translate([hinge_axis_x, 0, 0])
                rotate([0, open_angle, 0])
                    translate([-hinge_axis_x, 0, 0])
                        color("green")
                            A(anchor=TOP) {

                                // 上半盒铰链也要跟着上半盒一起转
                                position(TOP + LEFT)
                                    orient(anchor=LEFT)
                                        knuckle_hinge(
                                            length=35,
                                            segs=9,
                                            offset=hinge_offset,
                                            arm_height=1,
                                            seg_ratio=1,
                                            inner=true,
                                            in_place=true
                                        );
                            }
        }
    }
}