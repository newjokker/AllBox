include <BOSL2/std.scad>

/*
 * ESP32 卡扣盒公共建模内核。
 *
 * 本文件只放派生尺寸、校验、函数和建模模块；
 * 每块开发板的尺寸及矩阵参数放在各自的 *_shell.scad 配置文件中。
 */

/* [Hidden] */
// 用户输入的是内部净尺寸；以下尺寸用于生成外壳，不需要手动设置。
outer_width = box_width + 2 * wall;
outer_length = box_length + 2 * wall;
base_outer_height = bottom_t + base_height;

pcb_support_max_height = len(pcb_support_matrix) > 0
    ? max([for (support=pcb_support_matrix) support[4]])
    : 0;
pcb_bottom_z = bottom_t + pcb_support_max_height;

lower_lip_wall = (wall - fit_gap) / 2;
lid_lip_cut = (wall + fit_gap) / 2;
bump_r = 0.65;
button_plunger_top_z = lid_height - top_t + epsilon;
lid_inner_ceiling_z = lid_height - top_t;

function button_bottom_z(button) = button_plunger_top_z - button[3];
function lowest_button_bottom_z() =
    min([for (button=button_matrix) button_bottom_z(button)]);
function fix_post_bottom_z(post) = lid_inner_ceiling_z - post[3];
function lowest_fix_post_bottom_z() = len(lid_fix_post_matrix) > 0
    ? min([for (post=lid_fix_post_matrix) fix_post_bottom_z(post)])
    : lid_inner_ceiling_z;
function lowest_lid_feature_bottom_z() =
    min(lowest_button_bottom_z(), lowest_fix_post_bottom_z());
function clamp_value(value, low, high) = min(max(value, low), high);
function point_segment_distance(px, py, ax, ay, bx, by) =
    let(
        vx = bx - ax,
        vy = by - ay,
        length_sq = vx * vx + vy * vy,
        t = length_sq > 0
            ? clamp_value(((px - ax) * vx + (py - ay) * vy) / length_sq, 0, 1)
            : 0,
        nearest_x = ax + t * vx,
        nearest_y = ay + t * vy
    )
    sqrt((px - nearest_x) * (px - nearest_x) +
         (py - nearest_y) * (py - nearest_y));
function vent_overlaps_fix_post(x, y, post) =
    sqrt((x - post[0]) * (x - post[0]) +
         (y - post[1]) * (y - post[1]))
    < vent_hole_diameter / 2
      + max(post[2], post[4]) / 2
      + lid_fix_post_vent_clearance;
function vent_clear_of_fix_posts(x, y) =
    len([for (post=lid_fix_post_matrix)
        if (vent_overlaps_fix_post(x, y, post)) 1]) == 0;
function vent_overlaps_button(x, y, button) =
    let(
        end_x = button[0] - sin(button[2]) * button_flexure_length,
        end_y = button[1] + cos(button[2]) * button_flexure_length,
        mechanism_radius = max(
            button_pad_diameter,
            button_flexure_width + 2 * button_slot_width
        ) / 2
    )
    point_segment_distance(
        x, y,
        button[0], button[1],
        end_x, end_y
    ) < vent_hole_diameter / 2 + mechanism_radius + button_vent_clearance;
function vent_clear_of_buttons(x, y) =
    len([for (button=button_matrix)
        if (vent_overlaps_button(x, y, button)) 1]) == 0;
function vent_overlaps_top_cutout(x, y, cutout) =
    cutout[0] == "top" &&
    abs(x - cutout[1]) < cutout[3] / 2 + vent_hole_diameter / 2 + top_cutout_vent_clearance &&
    abs(y - cutout[2]) < cutout[4] / 2 + vent_hole_diameter / 2 + top_cutout_vent_clearance;
function vent_clear_of_top_cutouts(x, y) =
    len([for (cutout=side_rect_cutout_matrix)
        if (vent_overlaps_top_cutout(x, y, cutout)) 1]) == 0;
function vent_inside_lid(x, y) =
    abs(x) + vent_hole_diameter / 2 + vent_edge_clearance <= box_width / 2 &&
    abs(y) + vent_hole_diameter / 2 + vent_edge_clearance <= box_length / 2;

assert(fit_gap >= 0 && fit_gap < wall, "fit_gap 必须小于 wall");
assert(box_width > pcb_size.x, "盒子内部净宽不足以容纳 PCB");
assert(box_length > pcb_size.y, "盒子内部净长不足以容纳 PCB");
assert(base_height > 0, "盒子内部净高必须大于 0");
assert(side_rect_cutout_depth > wall,
    "side_rect_cutout_depth 必须大于 wall，才能完全切穿侧壁");
assert(len(snap_bump_matrix) > 0, "snap_bump_matrix 至少需要一项");
assert(len(pin_row_matrix) > 0, "pin_row_matrix 至少需要一项");
assert(pin_slot_width > 0, "pin_slot_width 必须大于 0");
assert(pin_exposed_length >= 0, "pin_exposed_length 不能小于 0");
assert(len(button_matrix) > 0, "button_matrix 至少需要一项");
assert(button_pad_diameter > 2 * button_slot_width,
    "button_pad_diameter 必须大于两倍切缝宽度");
assert(button_flexure_length > button_pad_diameter / 2,
    "button_flexure_length 太短");
assert(button_flexure_width > 0 && button_slot_width > 0,
    "弹片宽度和切缝宽度必须大于 0");
assert(button_plunger_diameter > 0 && button_root_diameter >= button_plunger_diameter,
    "触点柱直径必须大于 0，根部圆台直径不能小于触点柱直径");
assert(button_root_height > 0, "button_root_height 必须大于 0");
assert(vent_hole_diameter > 0 && vent_pitch[0] > 0 && vent_pitch[1] > 0,
    "蜂窝孔直径和间距必须大于 0");
assert(vent_auto_fill || (vent_rows >= 1 && vent_columns >= 1),
    "固定区域蜂窝的 vent_rows 和 vent_columns 必须至少为 1");
assert(vent_pitch[0] >= vent_hole_diameter && vent_pitch[1] >= vent_hole_diameter,
    "蜂窝孔中心间距不能小于孔径，否则相邻孔会连在一起");
assert(vent_edge_clearance >= 0 && button_vent_clearance >= 0 &&
       top_cutout_vent_clearance >= 0,
    "蜂窝外圈和部件避让距离不能小于 0");

for (snap=snap_bump_matrix) {
    assert(len(snap) == 3, "每个卡扣必须是 [面, 位置, 长度]");
    assert(snap[0] == "left" || snap[0] == "right" ||
           snap[0] == "front" || snap[0] == "back",
        str("不支持的卡扣面: ", snap[0]));
    assert(snap[2] > 0, "卡扣条形长度必须大于 0");
}
for (pin=pin_row_matrix) {
    assert(len(pin) == 3, "每排引脚必须是 [X位置, Y位置, 开槽长度]");
    assert(pin[2] > 0, "排针开槽长度必须大于 0");
}

for (port=typec_cutout_matrix) {
    assert(len(port) == 7,
        "每个 Type-C 开口必须是 [面, 水平位置, 孔底距离, 宽度, 高度, 圆角, 切割深度]");
    assert(port[0] == "left" || port[0] == "right" ||
           port[0] == "front" || port[0] == "back",
        str("不支持的 Type-C 开口面: ", port[0]));
    assert(port[2] >= 0,
        "Type-C 开口下边缘到底板上表面的距离不能小于 0");
    assert(port[3] > 0 && port[4] > 0,
        "Type-C 开口宽度和高度必须大于 0");
    assert(port[5] >= 0 && port[5] < min(port[3], port[4]) / 2,
        "Type-C 开口圆角必须小于最短边的一半");
    assert(port[6] > wall,
        "Type-C 开口切割深度必须大于 wall，才能完全切穿侧壁");
    assert(!typec_enabled || port[2] + port[4] < base_height,
        str("Type-C 开口侵入卡扣 lip，请减小孔底距离或开口高度: ", port));
}

for (cutout=side_rect_cutout_matrix) {
    assert(len(cutout) == 6,
        "每个矩形出口必须是 [面, 位置1, 位置2, 尺寸1, 尺寸2, 圆角半径]");
    assert(cutout[0] == "left" || cutout[0] == "right" ||
           cutout[0] == "front" || cutout[0] == "back" ||
           cutout[0] == "bottom" || cutout[0] == "top",
        str("不支持的矩形出口面: ", cutout[0]));
    assert(cutout[3] > 0 && cutout[4] > 0,
        "矩形出口的两个方向尺寸必须大于 0");
    assert((cutout[0] == "bottom" || cutout[0] == "top") || cutout[2] >= 0,
        "矩形出口下边缘到底板上表面的距离不能小于 0");
    assert(cutout[5] >= 0 && cutout[5] < min(cutout[3], cutout[4]) / 2,
        "矩形出口圆角必须小于最短边的一半");
    assert((cutout[0] == "bottom" && side_rect_cutout_depth > bottom_t) ||
           (cutout[0] == "top" && side_rect_cutout_depth > top_t) ||
           ((cutout[0] == "front" || cutout[0] == "back" ||
             cutout[0] == "left" || cutout[0] == "right") &&
            side_rect_cutout_depth > wall),
        str("矩形出口切割深度不足，无法切穿所在面: ", cutout));
}

for (support=pcb_support_matrix) {
    assert(len(support) == 5, "每个托台必须是 [X, Y, X大小, Y大小, 高度]");
    assert(support[2] > 0 && support[3] > 0 && support[4] > 0,
        "托台大小和高度必须大于 0");
}

for (button=button_matrix) {
    assert(len(button) == 4,
        "每个按键必须是 [X位置, Y位置, 方向角度, 触点伸出长度]");
    assert(button[3] > button_root_height,
        "每个按键的触点伸出长度必须大于根部加强圆台高度");
}


for (post=lid_fix_post_matrix) {
    assert(len(post) == 6,
        "每个上盖固定柱必须是 [X, Y, 柱径, 向下长度, 根部直径, 根部高度]");
    assert(post[2] > 0 && post[3] > 0 && post[4] >= post[2] &&
           post[5] > 0 && post[5] < post[3],
        "上盖固定柱尺寸无效：根部直径不能小于柱径，根部高度必须小于向下长度");
    assert(abs(post[0]) + post[4] / 2 < box_width / 2 &&
           abs(post[1]) + post[4] / 2 < box_length / 2,
        str("上盖固定柱超出盒子内部范围: ", post));
}

assert(lid_fix_post_vent_clearance >= 0,
    "lid_fix_post_vent_clearance 不能小于 0");


// 与参考文件相同思路：只保留朝墙面外侧凸出的半圆胶囊。
module friction_bump(length, radius=bump_r) {
    difference() {
        translate([-radius * 0.45, 0, 0])
            rotate([90, 0, 0]) {
                cylinder(h=length, r=radius, center=true);
                translate([0, 0,  length / 2]) sphere(r=radius);
                translate([0, 0, -length / 2]) sphere(r=radius);
            }

        cuboid(
            [2 * radius, length + 2 * radius, 2 * radius],
            anchor=[1, 0, 0]
        );
    }
}


// 按矩阵中的面和位置放置卡扣；inset 是该层薄壁的内缩宽度。
module place_snap_bump(snap, inset, z_pos) {
    face = snap[0];
    pos = snap[1];
    length = snap[2];

    if (face == "right")
        translate([outer_width / 2 - inset - epsilon, pos, z_pos])
            friction_bump(length=length);
    else if (face == "left")
        translate([-outer_width / 2 + inset + epsilon, pos, z_pos])
            rotate([0, 180, 0])
                friction_bump(length=length);
    else if (face == "back")
        translate([pos, outer_length / 2 - inset - epsilon, z_pos])
            rotate([0, 0, 90])
                friction_bump(length=length);
    else
        translate([pos, -outer_length / 2 + inset + epsilon, z_pos])
            rotate([0, 0, -90])
                friction_bump(length=length);
}


module typec_cutouts() {
    if (typec_enabled)
        for (port=typec_cutout_matrix) {
            face = port[0];
            offset = port[1];
            bottom_gap = port[2];
            cut_width = port[3];
            cut_height = port[4];
            cut_radius = port[5];
            cut_depth = port[6];
            // 孔底距离以盒内底板上表面为基准，再换算为实体切孔中心 Z。
            z_pos = bottom_t + bottom_gap + cut_height / 2;

            if (face == "front")
                translate([offset, -outer_length / 2, z_pos])
                    cuboid(
                        [cut_width, cut_depth, cut_height],
                        rounding=cut_radius,
                        edges="Y",
                        anchor=CENTER
                    );
            else if (face == "back")
                translate([offset, outer_length / 2, z_pos])
                    cuboid(
                        [cut_width, cut_depth, cut_height],
                        rounding=cut_radius,
                        edges="Y",
                        anchor=CENTER
                    );
            else if (face == "left")
                translate([-outer_width / 2, offset, z_pos])
                    cuboid(
                        [cut_depth, cut_width, cut_height],
                        rounding=cut_radius,
                        edges="X",
                        anchor=CENTER
                    );
            else
                translate([outer_width / 2, offset, z_pos])
                    cuboid(
                        [cut_depth, cut_width, cut_height],
                        rounding=cut_radius,
                        edges="X",
                        anchor=CENTER
                    );
        }
    }


// 侧面矩形出口使用装配状态下的全局 Z 坐标。
// part 用于让 bottom 只切底盒、top 只切上盖；侧面出口仍同时作用于上下盖。
// z_offset=0 用于底盒；上盖传入 base_outer_height 后自动换算为上盖局部坐标。
module side_rect_cutouts(part="base", z_offset=0) {
    for (cutout=side_rect_cutout_matrix) {
        face = cutout[0];
        offset = cutout[1];
        cut_width = cutout[3];
        cut_height = cutout[4];
        cut_radius = cutout[5];
        // 孔底间距以盒内底板上表面为基准，必须加上底板厚度后再换算中心 Z。
        z_pos = bottom_t + cutout[2] + cut_height / 2 - z_offset;

        if (face == "front")
            translate([offset, -outer_length / 2, z_pos])
                cuboid(
                    [cut_width, side_rect_cutout_depth, cut_height + 2 * epsilon],
                    rounding=cut_radius,
                    edges="Y",
                    anchor=CENTER
                );
        else if (face == "back")
            translate([offset, outer_length / 2, z_pos])
                cuboid(
                    [cut_width, side_rect_cutout_depth, cut_height + 2 * epsilon],
                    rounding=cut_radius,
                    edges="Y",
                    anchor=CENTER
                );
        else if (face == "left")
            translate([-outer_width / 2, offset, z_pos])
                cuboid(
                    [side_rect_cutout_depth, cut_width, cut_height + 2 * epsilon],
                    rounding=cut_radius,
                    edges="X",
                    anchor=CENTER
                );
        else if (face == "right")
            translate([outer_width / 2, offset, z_pos])
                cuboid(
                    [side_rect_cutout_depth, cut_width, cut_height + 2 * epsilon],
                    rounding=cut_radius,
                    edges="X",
                    anchor=CENTER
                );
        else if (face == "bottom" && part == "base")
            translate([cutout[1], cutout[2], bottom_t / 2])
                cuboid(
                    [cutout[3], cutout[4], side_rect_cutout_depth],
                    rounding=cut_radius,
                    edges="Z",
                    anchor=CENTER
                );
        else if (face == "top" && part == "lid")
            translate([cutout[1], cutout[2], lid_height - top_t / 2])
                cuboid(
                    [cutout[3], cutout[4], side_rect_cutout_depth],
                    rounding=cut_radius,
                    edges="Z",
                    anchor=CENTER
                );
    }
}


module base_shell() {
    difference() {
        union() {
            // BOSL2 圆角底板。
            cuboid(
                [outer_width, outer_length, bottom_t],
                rounding=corner_r,
                edges="Z",
                anchor=BOT
            );

            // BOSL2 开口盒壁。
            translate([0, 0, bottom_t - epsilon])
                rect_tube(
                    size=[outer_width, outer_length],
                    wall=wall,
                    h=base_height + 2 * epsilon,
                    rounding=corner_r,
                    anchor=BOT
                );

            // 外包式卡扣唇边。
            translate([0, 0, base_outer_height - epsilon])
                rect_tube(
                    size=[outer_width, outer_length],
                    wall=lower_lip_wall,
                    h=lip_h + epsilon,
                    rounding=corner_r,
                    anchor=BOT
                );

            pcb_supports();
        }

        // 两排引脚从盒底伸出，不再切开左右侧壁。
        for (pin=pin_row_matrix)
            translate([pin[0], pin[1], bottom_t / 2])
                cuboid(
                    [pin_slot_width, pin[2], bottom_t + 2 * epsilon],
                    rounding=min(1.2, pin_slot_width / 2 - epsilon),
                    edges="Z",
                    anchor=CENTER
                );

        // 参数化 Type-C 插口；默认高度限制在下盒主体内，不切入卡扣唇边。
        typec_cutouts();

        // 下盒唇边上的卡扣凹槽，与上盖凸条共用同一矩阵。
        for (snap=snap_bump_matrix)
            place_snap_bump(
                snap=snap,
                inset=lower_lip_wall,
                z_pos=base_outer_height + lip_h / 2
            );

        // 最高优先级矩形出口：侧面孔在 lip 后切除，bottom 孔同时贯穿底板。
        side_rect_cutouts(part="base");
    }
}


// 四个内角托台托住 PCB，完全避开底部两排引脚槽。
module pcb_supports() {
    for (support=pcb_support_matrix)
        translate([support[0], support[1], bottom_t - epsilon])
            cuboid(
                [support[2], support[3], support[4] + epsilon],
                rounding=min(0.7, min(support[2], support[3]) / 2 - epsilon),
                edges="Z",
                anchor=BOT
            );
}


module lid_shell() {
    union() {
        difference() {
            union() {
                difference() {
                    union() {
                        // 上盖顶板。
                        translate([0, 0, lid_height - top_t - epsilon])
                            cuboid(
                                [outer_width, outer_length, top_t + epsilon],
                                rounding=corner_r,
                                edges="Z",
                                anchor=BOT
                            );

                        // 上盖侧壁。
                        rect_tube(
                            size=[outer_width, outer_length],
                            wall=wall,
                            h=lid_height - top_t + epsilon,
                            rounding=corner_r,
                            anchor=BOT
                        );
                    }

                    // 让掉外圈，留下能插入下盒唇边内侧的薄壁。
                    translate([0, 0, -epsilon])
                        rect_tube(
                            size=[outer_width, outer_length],
                            wall=lid_lip_cut,
                            h=lip_h + 2 * epsilon,
                            rounding=corner_r,
                            anchor=BOT
                        );
                }

                // 与下盒凹槽配合的上盖凸条。
                for (snap=snap_bump_matrix)
                    place_snap_bump(
                        snap=snap,
                        inset=lid_lip_cut,
                        z_pos=lip_h / 2
                    );

                // 圆形按压头和下方触点柱与悬臂舌片连成一体。
                button_actuators();
            }

            // 围绕按压头切出 C 形缝和两条长缝，留下朝盒子中部连接的弹性舌片。
            button_flexure_cuts();

            // 顶盖蜂窝散热区会主动避开固定柱。
            honeycomb_vents();

            // 与底盒使用同一矩阵；侧面孔同步切掉插入段，top 孔贯穿顶板。
            side_rect_cutouts(part="lid", z_offset=base_outer_height);
        }

        // 固定柱最后生成，优先级高于蜂窝和其他切孔。
        lid_fix_posts();
    }
}


// 一体式可按压机构：顶面圆形按压舌片 + 根部带斜面加强圆台的内侧触点柱。
// 触点柱先按常见 DevKit 按键高度预留，后续应根据实物板微调长度。
module button_actuators() {
    root_head_bottom = button_plunger_top_z - button_root_height;

    for (button=button_matrix) {
        button_x = button[0];
        button_y = button[1];
        plunger_bottom = button_bottom_z(button);

        // 顶面不再额外凸起，圆形舌片本身就是手指按压面。
        // 触点末端保持细圆柱和平底。
        translate([button_x, button_y, plunger_bottom])
            cylinder(
                h=root_head_bottom - plunger_bottom + epsilon,
                d=button_plunger_diameter,
                $fn=32
            );

        // 喇叭形圆台移到连接根部：靠顶盖宽，朝触点柱方向逐渐收窄。
        translate([button_x, button_y, root_head_bottom])
            underside_button_root();
    }
}


module underside_button_root() {
    shaft_r = button_plunger_diameter / 2;
    root_r = button_root_diameter / 2;

    rotate_extrude(convexity=4, $fn=64)
        polygon(points=[
            [0,    0],
            [shaft_r, 0],
            [shaft_r + (root_r - shaft_r) * 0.36, button_root_height * 0.19],
            [root_r - (root_r - shaft_r) * 0.10, button_root_height * 0.66],
            [root_r, button_root_height * 0.86],
            [root_r, button_root_height],
            [0,      button_root_height]
        ]);
}


// 上盖内侧固定柱：细柱向下压住 PCB，靠近顶盖处用圆台加宽并加强连接。
module lid_fix_posts() {
    for (post=lid_fix_post_matrix) {
        post_x = post[0];
        post_y = post[1];
        shaft_d = post[2];
        down_length = post[3];
        root_d = post[4];
        root_h = post[5];
        post_bottom = lid_inner_ceiling_z - down_length;
        root_bottom = lid_inner_ceiling_z - root_h;

        // 向下的主体圆柱。
        translate([post_x, post_y, post_bottom])
            cylinder(
                h=down_length - root_h + epsilon,
                d=shaft_d,
                $fn=40
            );

        // 顶盖连接处的锥形加强根部，末端略微进入顶板以保证实体连接。
        translate([post_x, post_y, root_bottom])
            cylinder(
                h=root_h + epsilon,
                d1=shaft_d,
                d2=root_d,
                $fn=48
            );
    }
}


module button_flexure_cuts() {
    ring_inner_d = button_pad_diameter - 2 * button_slot_width;
    tongue_half_w = button_flexure_width / 2;
    cut_z = lid_height - top_t - 2 * epsilon;
    cut_h = top_t + 4 * epsilon;

    for (button=button_matrix)
        translate([button[0], button[1], cut_z])
            rotate([0, 0, button[2]]) {
                linear_extrude(height=cut_h)
                    difference() {
                        difference() {
                            circle(d=button_pad_diameter, $fn=64);
                            circle(d=ring_inner_d, $fn=64);
                        }

                        // 在弹片延伸方向保留桥接，让圆头与悬臂相连。
                        translate([-tongue_half_w, 0])
                            square([2 * tongue_half_w, button_pad_diameter]);
                    }

                // 两条圆头长缝形成可弯曲舌片。
                for (side=[-1, 1])
                    hull() {
                        translate([
                            side * (button_pad_diameter / 2 - button_slot_width / 2),
                            0,
                            0
                        ]) cylinder(h=cut_h, d=button_slot_width, $fn=20);

                        translate([
                            side * (button_pad_diameter / 2 - button_slot_width / 2),
                            button_flexure_length,
                            0
                        ]) cylinder(h=cut_h, d=button_slot_width, $fn=20);
                    }
            }
}


module honeycomb_hole(x, y) {
    // 从盖子底部以下一直切到顶面以上，避免共面布尔留下薄膜。
    translate([x, y, -epsilon])
        cylinder(
            h=lid_height + 2 * epsilon,
            d=vent_hole_diameter,
            $fn=6
        );
}


module honeycomb_vents() {
    row_count = ceil(box_length / (2 * vent_pitch[1])) + 1;
    column_count = ceil(box_width / (2 * vent_pitch[0])) + 1;

    if (vent_enabled && vent_auto_fill)
        for (row=[-row_count:row_count], col=[-column_count:column_count]) {
            // 奇数行错开半个横向间距，自动铺满整个顶盖可用区域。
            stagger = ((abs(row) % 2) == 0 ? 0 : vent_pitch[0] / 2);
            x = col * vent_pitch[0] + stagger;
            y = row * vent_pitch[1];

            if (vent_inside_lid(x, y) &&
                vent_clear_of_buttons(x, y) &&
                vent_clear_of_fix_posts(x, y) &&
                vent_clear_of_top_cutouts(x, y))
                honeycomb_hole(x, y);
        }
    else if (vent_enabled)
        for (row=[0:vent_rows - 1], col=[0:vent_columns - 1]) {
            row_offset = row - (vent_rows - 1) / 2;
            col_offset = col - (vent_columns - 1) / 2;
            // 保留旧版固定区域蜂窝的居中错位方式，避免配置迁移后外观变化。
            stagger = ((row % 2) == 0 ? -vent_pitch[0] / 4 : vent_pitch[0] / 4);
            x = vent_center[0] + col_offset * vent_pitch[0] + stagger;
            y = vent_center[1] + row_offset * vent_pitch[1];

            if (abs(x - vent_center[0]) + vent_hole_diameter / 2 <= vent_area_size[0] / 2 &&
                abs(y - vent_center[1]) + vent_hole_diameter / 2 <= vent_area_size[1] / 2 &&
                abs(x) + vent_hole_diameter / 2 < box_width / 2 &&
                abs(y) + vent_hole_diameter / 2 < box_length / 2 &&
                vent_clear_of_fix_posts(x, y))
                honeycomb_hole(x, y);
        }
}


module pcb_preview() {
    %translate([0, 0, pcb_bottom_z])
        color([0.05, 0.35, 0.18, 0.65])
            cuboid(pcb_size, anchor=BOT);

    // 两排排针向下穿过底板长槽。
    for (pin=pin_row_matrix) {
        // 金属针脚从 PCB 底面一直延伸到盒底以下指定长度。
        %translate([pin[0], pin[1], -pin_exposed_length])
            color([0.72, 0.55, 0.12, 0.7])
                cuboid(
                    [1.2, max(pin[2] - 1, 1), pcb_bottom_z + pin_exposed_length],
                    anchor=BOT
                );

        %translate([pin[0], pin[1], pcb_bottom_z + pcb_size.z])
            color([0.12, 0.12, 0.12, 0.65])
                cuboid([2.5, max(pin[2] - 1, 1), 2.5], anchor=BOT);
    }
}


module show_model() {
    if (layout == "assembly") {
        if (part == "both" || part == "base") base_shell();
        if (part == "both" || part == "lid")
            translate([0, 0, base_outer_height]) lid_shell();
        if ($preview) pcb_preview();
    }
    else if (layout == "print") {
        if (part == "both" || part == "base")
            translate([-(outer_width / 2 + 5), 0, 0]) base_shell();

        if (part == "both" || part == "lid")
            translate([outer_width / 2 + 5, 0, lid_height])
                rotate([180, 0, 0]) lid_shell();
    }
    else {
        // 打开视图：下盒在左，盖子翻开后放在右侧，便于检查内部结构。
        if (part == "both" || part == "base") {
            translate([-(outer_width / 2 + 7), 0, 0]) base_shell();
            if ($preview)
                translate([-(outer_width / 2 + 7), 0, 0]) pcb_preview();
        }

        if (part == "both" || part == "lid")
            // 外表面朝上展示；整体抬高，使内侧触点柱不会穿过展示平面。
            translate([
                outer_width / 2 + 7,
                0,
                max(0, -lowest_lid_feature_bottom_z())
            ]) lid_shell();
    }
}
