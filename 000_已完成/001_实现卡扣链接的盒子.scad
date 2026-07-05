include <BOSL2/std.scad>

/* [模型尺寸 / Box Size] */
// 盒子外宽，单位 mm
box_width = 40;             // [30:1:120]
// 盒子外长，单位 mm
box_length = 70;           // [40:1:220]
// 上盖高度，单位 mm
upper_box_height = 10;      // [6:1:60]
// 下盒高度，单位 mm
lower_box_height = 14;      // [8:1:100]

/* [盒体结构 / Shell] */
// 四周墙壁厚度，因为有唇边和摩擦凸点，需要稍微厚一点
wall_thickness = 2;         // [1.5:0.2:3.5]
// 盒子底盖厚度
bottom_thickness = 1.2;     // [0.8, 1.0, 1.2, 1.4, 1.6]
// 盒子转角圆角半径
rounding = 5;               // [3:1:15]
// 盒子闭合底面转角样式
box_corner_style = "rounded";  // [flat, rounded]
// 唇边高度
lip_height = 3;             // [1:0.5:3]
// 上下盒口错开唇边之间的装配间隙
lip_fit_gap = 0.2;          // [0:0.05:0.8]

/* [闭合摩擦点 / Friction Bumps] */
// 正面摩擦凸点个数
front_bump_count = 4;       // [1:1:8]
// 侧面摩擦凸点个数
side_bump_count = 2;        // [1:1:8]
// 摩擦凸点长度
bump_length = 4;            // [1:0.5:4]
// 摩擦凸点两端球半径
bump_radius = 1;          // [0.6:0.1:2]

/* [手指槽 / Finger Notch] */
// 是否生成手指槽
enable_finger_notch = false; // [true, false]
// 是否生成手指防滑线
enable_grip_lines = true;   // [true, false]
// 手指防滑线长度
grip_line_length = 20;      // [5:1:30]
// 手指防滑线两端半球半径
grip_line_radius = 0.4;     // [0.4:0.2:1.2]
// 较小非 lip 侧壁区域内的手指防滑线数量，较大区域会自动按相同密度补线
grip_line_count = 4;        // [2:1:8]
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


/* [Hidden] */

/* [渲染 / Render] */
// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 128;     // [48, 64, 96, 128]

$fn = model_resolution;

upper_box_size = [box_width, box_length, upper_box_height];
lower_box_size = [box_width, box_length, lower_box_height];
lip_cut_slop = 0.01;
bump_attach_overlap = 0.03;

function checked_lip_fit_gap(w) =
    assert(lip_fit_gap >= 0, "lip_fit_gap must be >= 0")
    assert(lip_fit_gap < w, "lip_fit_gap must be smaller than wall_thickness")
    lip_fit_gap;

function lower_lip_width(w) =
    (w - checked_lip_fit_gap(w)) / 2;

function upper_lip_width(w) =
    (w + checked_lip_fit_gap(w)) / 2;

function lower_lip_width_ratio(w) =
    lower_lip_width(w) / w;

function upper_lip_width_ratio(w) =
    upper_lip_width(w) / w;

function closed_end_edges(closed_end) =
    closed_end == "top"
        ? [TOP, FRONT+LEFT, FRONT+RIGHT, BACK+LEFT, BACK+RIGHT]
        : [BOTTOM, FRONT+LEFT, FRONT+RIGHT, BACK+LEFT, BACK+RIGHT];


// 手指槽在 Y 方向影响到的半宽。
// 落在这个范围里的匹配凸点会显得残缺或多余。
function finger_notch_half_width() =
    max(notch_upper_length, notch_lower_length) / 2
    + bump_length / 2
    + bump_radius
    + notch_bump_clearance;

function finger_notch_affects_bump(y_pos) =
    enable_finger_notch && abs(y_pos) <= finger_notch_half_width();


function lower_grip_available_height() =
    lower_box_size.z - 2 * grip_line_radius;

function upper_grip_available_height() =
    upper_box_size.z - lip_height - 2 * grip_line_radius;

function grip_reference_height() =
    min(lower_grip_available_height(), upper_grip_available_height());

function grip_line_pitch() =
    grip_reference_height() / (grip_line_count + 1);

function grip_zone_center(top_z=0) =
    top_z / 2;

function finger_grip_z(index, top_z=0) =
    grip_zone_center(top_z)
    + (index - (grip_line_count + 1) / 2) * grip_line_pitch();


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


module flat_bottom_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    bottom_t=2,
    corner_r=8
) {
    cuboid(
        [outer_size.x, outer_size.y, bottom_t],
        rounding=corner_r,
        edges="Z",
        anchor=BOT
    );

    translate([0, 0, bottom_t])
        rect_tube(
            size=outer_size,
            wall=wall,
            h=box_height - bottom_t,
            rounding=corner_r,
            anchor=BOT
        );
}


module rounded_closed_end_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    closed_t=2,
    corner_r=8,
    closed_end="bottom"
) {
    inner_size = [
        outer_size.x - wall * 2,
        outer_size.y - wall * 2,
        box_height - closed_t + 0.02
    ];
    inner_z = closed_end == "top" ? -0.01 : closed_t;
    inner_r = max(corner_r - wall, 0.01);
    round_edges = closed_end_edges(closed_end);

    difference() {
        cuboid(
            [outer_size.x, outer_size.y, box_height],
            rounding=corner_r,
            edges=round_edges,
            anchor=BOT
        );

        translate([0, 0, inner_z])
            cuboid(
                inner_size,
                rounding=inner_r,
                edges=round_edges,
                anchor=BOT
            );
    }
}


module flat_closed_end_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    closed_t=2,
    corner_r=8,
    closed_end="bottom"
) {
    if (closed_end == "top") {
        rect_tube(
            size=outer_size,
            wall=wall,
            h=box_height - closed_t,
            rounding=corner_r,
            anchor=BOT
        );

        translate([0, 0, box_height - closed_t])
            cuboid(
                [outer_size.x, outer_size.y, closed_t],
                rounding=corner_r,
                edges="Z",
                anchor=BOT
            );
    } else {
        flat_bottom_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            bottom_t=closed_t,
            corner_r=corner_r
        );
    }
}


module selectable_open_box(
    outer_size=[100, 80],
    box_height=35,
    wall=2,
    closed_t=2,
    corner_r=8,
    closed_end="bottom"
) {
    assert(
        box_corner_style == "flat" || box_corner_style == "rounded",
        str("box_corner_style must be \"flat\" or \"rounded\", got: ", box_corner_style)
    );

    if (box_corner_style == "rounded")
        rounded_closed_end_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            closed_t=closed_t,
            corner_r=corner_r,
            closed_end=closed_end
        );
    else
        flat_closed_end_open_box(
            outer_size=outer_size,
            box_height=box_height,
            wall=wall,
            closed_t=closed_t,
            corner_r=corner_r,
            closed_end=closed_end
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
        lower_bump_x = size.x / 2 - lip_width_ratio * wall - bump_attach_overlap;
        lower_bump_y = size.y / 2 - lip_width_ratio * wall - bump_attach_overlap;

        difference() {
            union() {
                selectable_open_box(
                    outer_size=size,
                    box_height=height,
                    wall=wall,
                    closed_t=bottom_thickness,
                    corner_r=rounding,
                    closed_end="bottom"
                );

                // 外包的下盒唇边
                translate([0, 0, height])
                    rect_tube(
                        size=size,
                        wall=wall * lip_width_ratio,
                        h=lip_height,
                        rounding=rounding,
                        anchor=BOT
                    );

                if (enable_grip_lines) {
                    // 下盒侧面防滑线，避开 lip 区域。
                    for (i=[1:1:grip_line_count]) {
                        z_pos = finger_grip_z(i, height);
                        translate([size.x / 2, 0, z_pos])
                            friction_bump(grip_line_length, grip_line_radius);
                    }
                }
            }

            // 下盒外包唇边内侧摩擦凹点
            for (i=[1:1:front_bump_count]) {
                y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
                if (!finger_notch_affects_bump(y_pos))
                    translate([lower_bump_x, y_pos, height + lip_height / 2])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:front_bump_count]) {
                y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
                translate([-lower_bump_x, y_pos, height + lip_height / 2])
                    rotate([0, 180, 0])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:side_bump_count]) {
                x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
                translate([x_pos, lower_bump_y, height + lip_height / 2])
                    rotate([0, 0, 90])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:side_bump_count]) {
                x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
                translate([x_pos, -lower_bump_y, height + lip_height / 2])
                    rotate([0, 0, -90])
                        friction_bump(bump_length, bump_radius);
            }

            if (enable_finger_notch) {
                // 手指槽切在下盒外包唇边上，露出盖子边缘方便开启。
                translate([size.x / 2 - notch_thickness / 2, 0, height + lip_height - notch_height])
                    finger_notch(
                        upper_length=notch_upper_length,
                        lower_length=notch_lower_length,
                        height=notch_height,
                        thickness=notch_thickness
                    );
            }
        }
    }
    else {
        // 上半盒：外圈让位后留下内侧唇边，被下盒唇边包住
        cut_lip_height = abs(lip_height);
        cut_lip_width = wall * lip_width_ratio + lip_cut_slop;
        upper_bump_x = size.x / 2 - cut_lip_width - bump_attach_overlap;
        upper_bump_y = size.y / 2 - cut_lip_width - bump_attach_overlap;

        union() {
            difference() {
                union() {
                    selectable_open_box(
                        outer_size=size,
                        box_height=height,
                        wall=wall,
                        closed_t=bottom_thickness,
                        corner_r=rounding,
                        closed_end="bottom"
                    );
                }

                // 外圈让位
                translate([0, 0, height - cut_lip_height + 0.01])
                    rect_tube(
                        size=size,
                        wall=cut_lip_width,
                        h=cut_lip_height,
                        rounding=rounding,
                        anchor=BOT
                    );
            }

            // 盖子内侧唇边外侧的摩擦凸点
            for (i=[1:1:front_bump_count]) {
                y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
                if (!finger_notch_affects_bump(y_pos))
                    translate([upper_bump_x, y_pos, height - cut_lip_height / 2])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:front_bump_count]) {
                y_pos = -size.y / 2 + (size.y / (front_bump_count + 1)) * i;
                translate([-upper_bump_x, y_pos, height - cut_lip_height / 2])
                    rotate([0, 180, 0])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:side_bump_count]) {
                x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
                translate([x_pos, upper_bump_y, height - cut_lip_height / 2])
                    rotate([0, 0, 90])
                        friction_bump(bump_length, bump_radius);
            }

            for (i=[1:1:side_bump_count]) {
                x_pos = -size.x / 2 + (size.x / (side_bump_count + 1)) * i;
                translate([x_pos, -upper_bump_y, height - cut_lip_height / 2])
                    rotate([0, 0, -90])
                        friction_bump(bump_length, bump_radius);
            }

            if (enable_grip_lines) {
                // 上盖侧面防滑线，避开 lip 区域。
                for (i=[1:1:grip_line_count]) {
                    z_pos = finger_grip_z(i, height - cut_lip_height);
                    translate([size.x / 2, 0, z_pos])
                        friction_bump(grip_line_length, grip_line_radius);
                }
            }
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
        lip_width_ratio=lower_lip_width_ratio(wall_thickness)
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
        lip_width_ratio=upper_lip_width_ratio(wall_thickness)
    );
}


// ---------------- 主体预览 ----------------

// 下半盒放左边
translate([-upper_box_size.x * 0.7, 0, 0])
    lower_box();

// 上半盒放右边，方便单独查看
translate([upper_box_size.x * 0.7, 0, 0])
    upper_box();
