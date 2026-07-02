include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

/* [模型尺寸 / Box Size] */
// 盒子外宽，单位 mm
box_width = 50;             // [30:1:120]
// 盒子外长，单位 mm
box_length = 150;           // [60:1:250]
// 上盖高度，单位 mm
upper_box_height = 30;      // [6:1:60]
// 下盒高度，单位 mm
lower_box_height = 50;      // [8:1:100]
// 盒盖打开角度，0 为闭合，180 为完全展开
open_angle = 180;           // [0:10:180]

/* [盒体结构 / Shell] */
// 四周墙壁厚度，因为有唇边和摩擦凸点，需要稍微厚一点
wall_thickness = 2;         // [1.5:0.2:3.5]
// 盒子底盖厚度
bottom_thickness = 1.2;     // [0.8, 1.0, 1.2, 1.4, 1.6]
// 盒子转角圆角半径
rounding = 8;               // [3:1:15]
// 唇边高度
lip_height = 2;             // [1:0.5:3]
// 下半盒凸出唇边宽度比例
lower_lip_width_ratio = 0.5; // [0.3:0.05:0.8]
// 上半盒内凹唇边宽度比例
upper_lip_width_ratio = 0.55; // [0.3:0.05:0.8]

/* [铰链 / Hinge] */
// 铰链长度，建议小于盒子外长
hinge_length = 112.5;       // [40:0.5:220]
// 铰链节数量，建议使用奇数
hinge_seg = 9;              // [3:2:15]
// 上下铰链节长度比例
hinge_seg_ratio = 1;        // [0.3:0.1:2]
// 销轴孔间隙
hinge_clearance = 0.35;     // [0.1:0.05:0.8]
// 铰链节之间的间隙，太小会紧，太大会松
hinge_gap = 0.25;           // [0.1:0.05:0.8]
// 铰链底座厚度，盒体高度差较大时可以适当加大
hinge_offset = 2.5;         // [1:0.5:6]
// 铰链安装臂基础高度
hinge_arm_base_height = 1;  // [0:0.5:8]
// 铰链安装臂额外高度，用于补偿上下盒高度差
hinge_arm_extra_height = 12; // [0:0.5:40]
// 上盖铰链高度微调，平放预览时用于对齐上盖铰链
upper_hinge_z_lift = 20;    // [-20:0.5:60]

/* [闭合摩擦点 / Friction Bumps] */
// 正面摩擦凸点个数
front_bump_count = 6;       // [1:1:8]
// 侧面摩擦凸点个数
side_bump_count = 2;        // [1:1:8]
// 摩擦凸点长度
bump_length = 2;            // [1:0.5:4]
// 摩擦凸点两端球半径
bump_radius = 0.8;          // [0.4:0.1:2]

/* [手指槽 / Finger Notch] */
// 手指防滑线长度
grip_line_length = 20;      // [5:1:30]
// 手指防滑线两端半球半径
grip_line_radius = 0.4;     // [0.4:0.2:1.2]
// 手指防滑线数量
grip_line_count = 4;        // [2:1:8]
// 防滑线围绕手指槽向下延伸的高度
grip_zone_extra_height = 8; // [0:1:20]
// 手指槽上边长度
notch_upper_length = 10;    // [4:1:30]
// 手指槽下边长度
notch_lower_length = 20;    // [6:1:40]
// 手指槽高度
notch_height = 5;           // [2:0.5:12]
// 手指槽切割厚度
notch_thickness = 1.5;      // [0.5:0.5:4]
// 手指槽附近避开摩擦凸点的余量
notch_bump_clearance = 0.6; // [0:0.1:2]

/* [渲染 / Render] */
// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 128;     // [48, 64, 96, 128]

/* [Hidden] */
$fn = model_resolution;

upper_box_size = [box_width, box_length, upper_box_height];
box_size_z_down = lower_box_height;
lower_box_size = [box_width, box_length, lower_box_height];

// 铰链轴心距离盒子中心的 X 距离
hinge_axis_x = lower_box_size.x / 2 + hinge_offset;

// 铰链轴放在高度差的中点，180 度展开时两半盒子的外表面会共面。
hinge_axis_z = (upper_box_size.z - lower_box_size.z) / 2;

// 高度不一致时，铰链的安装臂需要多伸出一段去够到共同轴线。
hinge_arm_height = hinge_arm_base_height + hinge_arm_extra_height;

// 手指槽在 Y 方向影响到的半宽。落在这个范围里的匹配凸点会显得残缺或多余。
function finger_notch_half_width() =
    max(notch_upper_length, notch_lower_length) / 2
    + bump_length / 2
    + bump_radius
    + notch_bump_clearance;

function finger_notch_affects_bump(y_pos) =
    abs(y_pos) <= finger_notch_half_width();

// 防滑线只排在手指槽附近，避免上下盒高度不同造成整高均分后视觉不一致。
function finger_grip_zone_height(height) =
    min(height - 2 * grip_line_radius, notch_height + grip_zone_extra_height);

function finger_grip_zone_bottom(height) =
    max(
        grip_line_radius,
        min(
            height - grip_line_radius - finger_grip_zone_height(height),
            height - notch_height - grip_zone_extra_height
        )
    );

function finger_grip_z(index, height) =
    finger_grip_zone_bottom(height)
    + finger_grip_zone_height(height) * index / (grip_line_count + 1);


// 摩擦凸点, 用于盒子上下盖子连接
module friction_bump(bump_length, radius, height_ratio=0.5) {
    difference() {
        // 半边的圆柱太突出了，少一点
        translate([-radius * height_ratio, 0, 0])
            rotate([90, 0, 0]) {
                cylinder(h=bump_length, r=radius, center=true);

                translate([0, 0, bump_length / 2])
                    sphere(r=radius);

                translate([0, 0, -bump_length / 2])
                    sphere(r=radius);
            }

        cuboid(size=[2 * radius, bump_length + 2 * radius, 2 * radius], anchor=[1, 0, 0]);
    }
}

// 手指位，方便打开盒子
module finger_notch(upper_length=10, lower_length=20, height=5, thickness=2) {
    rotate([0, 0, 90])
        prismoid(
            size1=[upper_length, thickness],
            size2=[lower_length, thickness],
            h=height
        );
}

// 盒子的主体
module box_body(
    wall=2,
    bottom_thickness=2,
    size=[100, 80],
    height=40,
    rounding=5,
    lip_height=2,
    lip_width_ratio=0.5
) {
    if (lip_height > 0) {
        // 底板
        cuboid([size.x, size.y, bottom_thickness], rounding=rounding, edges="Z", anchor=BOT);

        // 盒子侧壁
        translate([0, 0, bottom_thickness])
            rect_tube(size=size, wall=wall, h=height - bottom_thickness, rounding=rounding, anchor=BOT);

        // 唇边
        translate([0, 0, height])
            rect_tube(
                size=[
                    size.x - wall * 2 + wall * 2 * lip_width_ratio,
                    size.y - wall * 2 + wall * 2 * lip_width_ratio
                ],
                wall=wall * lip_width_ratio,
                h=lip_height,
                rounding=rounding - wall * (1 - lip_width_ratio),
                anchor=BOT
            );

        // 摩擦凸点
        for (i=[1:1:front_bump_count]) {
            y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
            translate([size.x / 2 - (1 - lip_width_ratio) * wall, y_pos, height + lip_height / 2])
                friction_bump(bump_length, bump_radius);
        }

        for (i=[1:1:front_bump_count]) {
            y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
            if (!finger_notch_affects_bump(y_pos))
                translate([-(size.x / 2 - (1 - lip_width_ratio) * wall), y_pos, height + lip_height / 2])
                    rotate([0, 180, 0])
                        friction_bump(bump_length, bump_radius);
        }

        for (i=[1:1:side_bump_count]) {
            x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
            translate([x_pos, size.y / 2 - (1 - lip_width_ratio) * wall, height + lip_height / 2])
                rotate([0, 0, 90])
                    friction_bump(bump_length, bump_radius);
            }

        for (i=[1:1:side_bump_count]) {
            x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
            translate([x_pos, -(size.y / 2 - (1 - lip_width_ratio) * wall), height + lip_height / 2])
                rotate([0, 0, -90])
                    friction_bump(bump_length, bump_radius);
        }

        // 防滑槽
        for (i=[1:1:grip_line_count]) {
            z_pos = finger_grip_z(i, height);
            translate([-size.x / 2, 0, z_pos])
                rotate([0, 180, 0])
                    friction_bump(grip_line_length, grip_line_radius);
        }

    }
    else {

        // 凹进去的
        difference() {

            union() {
                // 底板
                cuboid([size.x, size.y, bottom_thickness], rounding=rounding, edges="Z", anchor=BOT);

                // 盒子侧壁
                translate([0, 0, bottom_thickness])
                    rect_tube(size=size, wall=wall, h=height - bottom_thickness, rounding=rounding, anchor=BOT);
            }

            // 唇边
            cut_lip_height = abs(lip_height);
            translate([0, 0, height - cut_lip_height + 0.01])
                rect_tube(
                    size=[
                        size.x - wall * 2 + wall * 2 * lip_width_ratio,
                        size.y - wall * 2 + wall * 2 * lip_width_ratio
                    ],
                    wall=wall * lip_width_ratio + 0.01,
                    h=cut_lip_height,
                    rounding=rounding - wall * (1 - lip_width_ratio),
                    anchor=BOT
                );

            // 摩擦凸点
            for (i=[1:1:front_bump_count]) {
                y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
                translate([size.x / 2 - lip_width_ratio * wall, y_pos, height - cut_lip_height / 2])
                    friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:front_bump_count]) {
                y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
                translate([-(size.x / 2 - lip_width_ratio * wall), y_pos, height - cut_lip_height / 2])
                    rotate([0, 180, 0])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:side_bump_count]) {
                x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
                translate([x_pos, size.y / 2 - lip_width_ratio * wall, height - cut_lip_height / 2])
                    rotate([0, 0, 90])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:side_bump_count]) {
                x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
                translate([x_pos, -(size.y / 2 - lip_width_ratio * wall), height - cut_lip_height / 2])
                    rotate([0, 0, -90])
                        friction_bump(bump_length, bump_radius);
            }

            // 手指槽
            translate([size.x / 2 - notch_thickness / 2, 0, height - notch_height])
                finger_notch(
                    upper_length=notch_upper_length,
                    lower_length=notch_lower_length,
                    height=notch_height,
                    thickness=notch_thickness
                );
        }

        difference() {

            union() {
                // 防滑槽
                for (i=[1:1:grip_line_count]) {
                    z_pos = finger_grip_z(i, height);
                    translate([size.x / 2, 0, z_pos])
                        friction_bump(grip_line_length, grip_line_radius);
                }
            }

            // 手指槽
            translate([size.x / 2, 0, height - notch_height])
                finger_notch(
                    upper_length=notch_upper_length,
                    lower_length=notch_lower_length,
                    height=notch_height,
                    thickness=notch_thickness + 50
                );
        }
    }
}

// 盒子改为可以 attach 的样式
module attachable_box_body(
    wall=2,
    bottom_thickness=2,
    size=[100, 80],
    height=40,
    rounding=5,
    lip_height=2,
    lip_width_ratio=0.5,
    body_z_offset=0,
    anchor=CENTER,
    spin=0,
    orient=UP
) {
    attach_height = height + max(lip_height, 0);

    attachable(anchor, spin, orient, size=[size.x, size.y, attach_height]) {
        translate([0, 0, -attach_height / 2 + body_z_offset])
            box_body(
                wall=wall,
                bottom_thickness=bottom_thickness,
                size=size,
                height=height,
                rounding=rounding,
                lip_height=lip_height,
                lip_width_ratio=lip_width_ratio
            );

        children();
    }
}


// 可接铰链的平底盒体模块
module hinged_box_half(
    size,
    height,
    lip_height=lip_height,
    anchor=CENTER,
    spin=0,
    orient=UP,
    box_hinge_z_offset=0,
    lip_width_ratio=0.5
) {
    attachable_box_body(
        wall=wall_thickness,
        bottom_thickness=bottom_thickness,
        size=size,
        height=height,
        rounding=rounding,
        lip_height=lip_height,
        lip_width_ratio=lip_width_ratio,
        body_z_offset=box_hinge_z_offset,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}

// 主体
translate([-hinge_axis_x, 0, 0])
{
    // 下半盒体
    hinged_box_half(
        size=[lower_box_size.x, lower_box_size.y],
        height=lower_box_size.z,
        lip_height=lip_height,
        anchor=TOP,
        box_hinge_z_offset=lip_height,
        lip_width_ratio=lower_lip_width_ratio
    ) {

        // 下半盒铰链
        translate([0, 0, hinge_axis_z])
            position(TOP + RIGHT)
                orient(anchor=RIGHT)
                    knuckle_hinge(
                        length=hinge_length,
                        segs=hinge_seg,
                        offset=hinge_offset,
                        arm_height=hinge_arm_base_height,
                        seg_ratio=hinge_seg_ratio,
                        in_place=true,
                        clearance=hinge_clearance,
                        gap=hinge_gap
                    );

        // 上半盒体
        attach(TOP, TOP) {
            // 上半盒整体绕铰链轴旋转
            translate([hinge_axis_x, 0, hinge_axis_z])
                rotate([0, open_angle, 0])
                    translate([-hinge_axis_x, 0, -hinge_axis_z])
                        hinged_box_half(
                            size=[upper_box_size.x, upper_box_size.y],
                            height=upper_box_size.z,
                            lip_height=-lip_height,
                            anchor=TOP,
                            lip_width_ratio=upper_lip_width_ratio
                            ) {
                                // 上半盒铰链跟着一起转
                                translate([0, 0, hinge_axis_z + upper_hinge_z_lift])
                                    position(TOP + LEFT)
                                        orient(anchor=LEFT)
                                            knuckle_hinge(
                                                length=hinge_length,
                                                segs=hinge_seg,
                                                offset=hinge_offset,
                                                arm_height=hinge_arm_height,
                                                seg_ratio=hinge_seg_ratio,
                                                inner=true,
                                                in_place=true,
                                                clearance=hinge_clearance,
                                                gap=hinge_gap
                                            );
                                }
        }
    }
}
