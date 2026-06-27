include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
include <盒子底部/底部平直的盒子.scad>

$fn = 164;


// ---------------- 参数 ----------------
box_size = [50, 40, 20];
hinge_offset = 2.5;
open_angle = 180;  // [0:10:180]
wall_thickness = 2;
bottom_thickness = 2;
rounding = 5;
lip_height = 1;
lip_width_index = 1;
box_hinge_z_offset = 0;  // 盒体相对铰链安装锚点的上下偏移，正数让盒体往上
hinge_length = min(35, box_size.y - 6);

// 铰链松紧参数
hinge_clearance = 0.35;   // 两半铰链之间的间隙
hinge_gap = 0.25;         // 铰链节之间的间隙

// 铰链轴心距离盒子中心的 X 距离
hinge_axis_x = box_size.x / 2 + hinge_offset;


// ---------------- 可接铰链的平底盒体模块 ----------------
module hinged_box_half(lip_height=lip_height, anchor=CENTER, spin=0, orient=UP, box_hinge_z_offset=0) {
    box_down_1(
        wall=wall_thickness,
        bottom_t=bottom_thickness,
        size=[box_size.x, box_size.y],
        height=box_size.z,
        rounding=rounding,
        lip_height=lip_height,
        lip_width_index=lip_width_index,
        body_z_offset=box_hinge_z_offset,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}


// ---------------- 主体 ----------------
translate([-hinge_axis_x, 0, 0]) 
{
    // 下半盒体
    hinged_box_half(lip_height=lip_height, anchor=TOP, box_hinge_z_offset=1) {

        // 下半盒铰链
        position(TOP + RIGHT)
            orient(anchor=RIGHT)
                knuckle_hinge(
                    length = hinge_length,
                    segs = 5,
                    offset = hinge_offset,
                    arm_height = 1,
                    seg_ratio = 1,
                    in_place = true,
                    clearance = hinge_clearance,
                    gap = hinge_gap
                );

        // 上半盒体
        attach(TOP, TOP) {

            // 上半盒整体绕铰链轴旋转
            translate([hinge_axis_x, 0, 0])
                rotate([0, open_angle, 0])
                    translate([-hinge_axis_x, 0, 0])
                        color("green")
                            hinged_box_half(lip_height=-lip_height, anchor=TOP) {

                                // 上半盒铰链跟着一起转
                                position(TOP + LEFT)
                                    orient(anchor=LEFT)
                                        knuckle_hinge(
                                            length = hinge_length,
                                            segs = 5,
                                            offset = hinge_offset,
                                            arm_height = 1,
                                            seg_ratio = 1,
                                            inner = true,
                                            in_place = true,

                                            clearance = hinge_clearance,
                                            gap = hinge_gap
                                        );
                            }
        }
    }
}
