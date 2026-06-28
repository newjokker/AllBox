include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
include <盒子底部/底部平直的盒子.scad>

$fn = 128;


// ---------------- 参数 ----------------
// 下半盒体尺寸：[宽, 长, 高]，高不包含 lip
lower_box_size = [60, 80, 15];

// 上半盒体尺寸：[宽, 长, 高]，高不包含 lip
// 宽和长建议先保持与下半一致，lip 才能正常扣合；高度可以独立设置。
upper_box_size = [60, 80, 10];

hinge_offset = 2.5;
open_angle = 90;  // [0:10:180]
wall_thickness = 2;
bottom_thickness = 2;
rounding = 5;
lip_height = 2;
lip_width_index_upper   = 0.5;
lip_width_index_down    = 0.55;
hinge_length = 60;

// 铰链松紧参数
hinge_clearance = 0.35;   // 两半铰链之间的间隙
hinge_gap = 0.25;         // 铰链节之间的间隙
hinge_arm_base_height = 1;
hinge_arm_extra_height = abs(lower_box_size.z - upper_box_size.z) / 2 + 3;

// 绿色上盖铰链的单独高度微调。
// 正数表示在 open_angle=180 平放预览时，把绿色铰链向上提。
upper_hinge_z_lift = 5;

// 铰链轴心距离盒子中心的 X 距离
hinge_axis_x = lower_box_size.x / 2 + hinge_offset;

// 上下高度不一致时，闭合基准仍在 lip 处；
// 铰链轴放在高度差的中点，180 度展开时两半盒子的外表面会共面。
hinge_axis_z = (upper_box_size.z - lower_box_size.z) / 2;

// 高度不一致时，铰链的安装臂需要多伸出一段去够到共同轴线。
// 如果预览里连接臂还不够长，可以只调大 hinge_arm_extra_height。
hinge_arm_height = hinge_arm_base_height + hinge_arm_extra_height;


// ---------------- 可接铰链的平底盒体模块 ----------------
module hinged_box_half(size, height, lip_height=lip_height, anchor=CENTER, spin=0, orient=UP, box_hinge_z_offset=0, lip_width_index=0.5) {
    box_down_1(
        wall=wall_thickness,
        bottom_t=bottom_thickness,
        size=size,
        height=height,
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
    hinged_box_half(
        size=[lower_box_size.x, lower_box_size.y],
        height=lower_box_size.z,
        lip_height=lip_height,
        anchor=TOP,
        box_hinge_z_offset=lip_height,
        lip_width_index=lip_width_index_upper
    ) {

        // 下半盒铰链
        translate([0, 0, hinge_axis_z])
            position(TOP + RIGHT)
                orient(anchor=RIGHT)
                    knuckle_hinge(
                        length = hinge_length,
                        segs = 5,
                        offset = hinge_offset,
                        arm_height = hinge_arm_base_height,
                        seg_ratio = 1,
                        in_place = true,
                        clearance = hinge_clearance,
                        gap = hinge_gap
                    );

        // 上半盒体
        attach(TOP, TOP) {
            // 上半盒整体绕铰链轴旋转
            translate([hinge_axis_x, 0, hinge_axis_z])
                rotate([0, open_angle, 0])
                    translate([-hinge_axis_x, 0, -hinge_axis_z])
                        color("green")
                            hinged_box_half(
                                size=[upper_box_size.x, upper_box_size.y],
                                height=upper_box_size.z,
                                lip_height=-lip_height,
                                anchor=TOP,
                                lip_width_index=lip_width_index_down
                            ) {
                                // 上半盒铰链跟着一起转
                                translate([0, 0, hinge_axis_z + upper_hinge_z_lift])
                                    position(TOP + LEFT)
                                        orient(anchor=LEFT)
                                            knuckle_hinge(
                                                length = hinge_length,
                                                segs = 5,
                                                offset = hinge_offset,
                                                arm_height = hinge_arm_height,
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
