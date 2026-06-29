include <BOSL2/std.scad>

$fn = 128;

// 上半盒子的尺寸
upper_box_size = [50, 100, 10];

// 下半盒体尺寸
lower_box_size = [upper_box_size.x, upper_box_size.y, 20];

// 四周墙壁的厚度，因为有唇边和摩擦凸点需要稍微厚一点
wall_thickness = 2;         // [1.5:0.2:3.5]

// 盒子底盖的厚度
bottom_thickness = 1.2;     // [0.8, 1.0, 1.2, 1.4, 1.6]

// 盒子转角的弧度
rounding = 8;               // [3:1:15]

// 唇边的高度
lip_height = 2;             // [1:0.5:3]

// 下半盒凸出唇边的宽度比例
lower_lip_width_ratio = 0.5;

// 上半盒内凹唇边的宽度比例
upper_lip_width_ratio = 0.55;

// 摩擦凹凸点正面凸点个数
front_bump_count = 6;       // [1:1:8]

// 摩擦凹凸点侧面凸点的个数
side_bump_count = 2;        // [1:1:8]

// 摩擦凹凸点凸点的长度
bump_length = 2;            // [1:0.5:4]

// 摩擦凹凸点凸点两端的球的半径
bump_radius = 0.8;          // [0.4:0.1:2]

// 手指防滑线的长度
grip_line_length = 20;      // [5:3:30]

// 手指防滑线的两端半球的半径
grip_line_radius = 0.4;     // [0.4:0.2:1.2]

// 手指防滑线的个数
grip_line_count = 4;        // [2:1:8]

// 手指防滑线围绕手指槽向下延伸的高度
grip_zone_extra_height = 12; // [0:1:20]

// 手指槽上边的长度
notch_upper_length = 10;

// 手指槽下边的长度
notch_lower_length = 20;

// 手指槽的高度
notch_height = 5;

// 手指槽的厚度，目前没用，为了切割前面的手指防滑线
notch_thickness = 1.5;

// 手指槽附近需要避开的摩擦凸点余量
notch_bump_clearance = 0.6; // [0:0.1:2]


// 手指槽在 Y 方向影响到的半宽。
// 落在这个范围里的匹配凸点会显得残缺或多余。
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


// 摩擦凸点，用于盒子上下盖子连接
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
// lip_height > 0：生成凸出的下半盒唇边
// lip_height < 0：生成内凹的上半盒唇边
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
        cuboid(
            [size.x, size.y, bottom_thickness],
            rounding=rounding,
            edges="Z",
            anchor=BOT
        );

        // 盒子侧壁
        translate([0, 0, bottom_thickness])
            rect_tube(
                size=size,
                wall=wall,
                h=height - bottom_thickness,
                rounding=rounding,
                anchor=BOT
            );

        // 凸出的唇边
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

        // 正面摩擦凸点
        for (i=[1:1:front_bump_count]) {
            y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
            translate([size.x / 2 - (1 - lip_width_ratio) * wall, y_pos, height + lip_height / 2])
                friction_bump(bump_length, bump_radius);
        }

        // 背面摩擦凸点，避开手指槽区域
        for (i=[1:1:front_bump_count]) {
            y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
            if (!finger_notch_affects_bump(y_pos))
                translate([-(size.x / 2 - (1 - lip_width_ratio) * wall), y_pos, height + lip_height / 2])
                    rotate([0, 180, 0])
                        friction_bump(bump_length, bump_radius);
        }

        // 左右两侧摩擦凸点
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

        // 防滑线
        for (i=[1:1:grip_line_count]) {
            z_pos = finger_grip_z(i, height);
            translate([-size.x / 2, 0, z_pos])
                rotate([0, 180, 0])
                    friction_bump(grip_line_length, grip_line_radius);
        }
    }
    else {
        // 上半盒：凹进去的唇边
        difference() {
            union() {
                // 顶盖主体底板
                cuboid(
                    [size.x, size.y, bottom_thickness],
                    rounding=rounding,
                    edges="Z",
                    anchor=BOT
                );

                // 顶盖侧壁
                translate([0, 0, bottom_thickness])
                    rect_tube(
                        size=size,
                        wall=wall,
                        h=height - bottom_thickness,
                        rounding=rounding,
                        anchor=BOT
                    );
            }

            // 内凹唇边
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

            // 摩擦凸点对应的凹槽
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

        // 防滑线，避开手指槽
        difference() {
            union() {
                for (i=[1:1:grip_line_count]) {
                    z_pos = finger_grip_z(i, height);
                    translate([size.x / 2, 0, z_pos])
                        friction_bump(grip_line_length, grip_line_radius);
                }
            }

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


// 下半盒
module lower_box() {
    box_body(
        wall=wall_thickness,
        bottom_thickness=bottom_thickness,
        size=[lower_box_size.x, lower_box_size.y],
        height=lower_box_size.z,
        rounding=rounding,
        lip_height=lip_height,
        lip_width_ratio=lower_lip_width_ratio
    );
}


// 上半盒
module upper_box() {
    box_body(
        wall=wall_thickness,
        bottom_thickness=bottom_thickness,
        size=[upper_box_size.x, upper_box_size.y],
        height=upper_box_size.z,
        rounding=rounding,
        lip_height=-lip_height,
        lip_width_ratio=upper_lip_width_ratio
    );
}


// ---------------- 主体预览 ----------------

// 下半盒放左边
translate([-upper_box_size.x * 0.7, 0, 0])
    lower_box();

// 上半盒放右边，方便单独查看
translate([upper_box_size.x * 0.7, 0, 0])
    upper_box();