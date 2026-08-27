include <BOSL2/std.scad>

/*
 * ESP32 DevKit 卡扣盒（第一版）
 *
 * 目标：先得到可运行、可打印、容易继续修改的基础结构。
 * - 下盒底部两排长孔让排针向下露出
 * - 前端开 USB 孔
 * - 上盖两个一体式悬臂按键机构
 * - 上盖蜂窝散热孔
 * - 上下盖沿用 001_实现卡扣链接的盒子.scad 的唇边 + 摩擦凸点结构
 *
 * 默认按常见 ESP32 DevKit（约 51 x 28 mm）预留空间。
 */

/* [显示] */
// 选择生成的零件：both=上下盒都显示，base=只显示下盒，lid=只显示上盖。
part = "both";              // [both,base,lid]

// 显示方式：open=打开并排，assembly=闭合装配，print=按打印方向并排摆放。
layout = "print";            // [open,assembly,print]

// ESP32 参考板，仅用于预览和定位，不参与导出实体。
pcb_size = [18.3, 39.5, 1.6];

/* [基础尺寸] */
// 盒子外宽，沿 X 方向，单位 mm；主要由 ESP32 PCB 宽度决定。
box_width = 26;
// 盒子外长，沿 Y 方向，单位 mm；USB 开口位于 -Y 方向的短边。
box_length = 42;
// 下盒主体高度，单位 mm；不包含上方额外伸出的卡扣唇边。
base_height = 6;
// 上盖总高度，单位 mm；从盖子开口端计算到顶面。
lid_height = 4;

/* [卡扣凹凸条] */
// 卡扣矩阵，每行格式：[所在面, 沿该面的中心位置, 条形长度]。
// left/right 面的位置沿 Y 方向；front/back 面的位置沿 X 方向，单位均为 mm。
// 增删矩阵行即可改变卡扣个数；同一矩阵同时生成下盒凹槽和上盖凸条。
snap_bump_matrix = [
    ["right", -12, 5.6],
    ["right",  12, 5.6],
    ["left",  -12, 5.6],
    ["left",   12, 5.6]
];

/* [底部排针] */
// 排针矩阵，每行格式：[X位置, Y位置, 底部开槽长度]，单位 mm。
pin_row_matrix = [
    [-7.2, 0, 32],
    [ 7.2, 0, 32]
];
// 每排排针开槽的宽度，单位 mm。
pin_slot_width = 2.8;

// 排针伸出盒子底面以下的长度，单位 mm；主要影响装配预览。
pin_exposed_length = 2;

/* [PCB托台] */
// 托台矩阵，每行格式：[X位置, Y位置, X方向大小, Y方向大小, 高度]，单位 mm。
// 增删矩阵行即可改变托台个数；PCB 预览高度采用矩阵中的最大托台高度。
pcb_support_matrix = [
    // [-9, -23.5, 3, 3, 0.1],
    // [-9,  23.5, 3, 3, 0.1],
    // [ 9, -23.5, 3, 3, 0.1],
    // [ 9,  23.5, 3, 3, 0.1]
];

/* [按压触点] */
// 从上盖内表面到触点柱平底末端的总伸出长度，单位 mm。
button_plunger_length = 2;

/* [Hidden] */
wall = 1.5;
bottom_t = 1.6;
top_t = 1.6;
corner_r = 4;
lip_h = 2.4;
fit_gap = 0.28;
epsilon = 0.04;
$fn = 64;


pcb_bottom_z = bottom_t + max([for (support=pcb_support_matrix) support[4]]);

lower_lip_wall = (wall - fit_gap) / 2;
lid_lip_cut = (wall + fit_gap) / 2;
bump_r = 0.65;
button_root_head_h = 1.45;
button_plunger_top_z = lid_height - top_t + epsilon;
button_plunger_bottom_z = button_plunger_top_z - button_plunger_length;

assert(fit_gap >= 0 && fit_gap < wall, "fit_gap 必须小于 wall");
assert(box_width > pcb_size.x + 1, "盒子宽度不足");
assert(box_length > pcb_size.y + 1, "盒子长度不足");
assert(len(snap_bump_matrix) > 0, "snap_bump_matrix 至少需要一项");
assert(len(pin_row_matrix) > 0, "pin_row_matrix 至少需要一项");
assert(pin_slot_width > 0, "pin_slot_width 必须大于 0");
assert(pin_exposed_length >= 0, "pin_exposed_length 不能小于 0");
assert(button_plunger_length > button_root_head_h,
    "button_plunger_length 必须大于根部斜面圆台高度");

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

for (support=pcb_support_matrix) {
    assert(len(support) == 5, "每个托台必须是 [X, Y, X大小, Y大小, 高度]");
    assert(support[2] > 0 && support[3] > 0 && support[4] > 0,
        "托台大小和高度必须大于 0");
}


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
        translate([box_width / 2 - inset - epsilon, pos, z_pos])
            friction_bump(length=length);
    else if (face == "left")
        translate([-box_width / 2 + inset + epsilon, pos, z_pos])
            rotate([0, 180, 0])
                friction_bump(length=length);
    else if (face == "back")
        translate([pos, box_length / 2 - inset - epsilon, z_pos])
            rotate([0, 0, 90])
                friction_bump(length=length);
    else
        translate([pos, -box_length / 2 + inset + epsilon, z_pos])
            rotate([0, 0, -90])
                friction_bump(length=length);
}


module base_shell() {
    difference() {
        union() {
            // BOSL2 圆角底板。
            cuboid(
                [box_width, box_length, bottom_t],
                rounding=corner_r,
                edges="Z",
                anchor=BOT
            );

            // BOSL2 开口盒壁。
            translate([0, 0, bottom_t - epsilon])
                rect_tube(
                    size=[box_width, box_length],
                    wall=wall,
                    h=base_height - bottom_t + 2 * epsilon,
                    rounding=corner_r,
                    anchor=BOT
                );

            // 外包式卡扣唇边。
            translate([0, 0, base_height - epsilon])
                rect_tube(
                    size=[box_width, box_length],
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

        // USB 插口，位于前端（-Y）。
        translate([0, -box_length / 2, 7.0])
            cuboid(
                [12, wall * 3, 7],
                rounding=1.3,
                edges="Y",
                anchor=CENTER
            );

        // 下盒唇边上的卡扣凹槽，与上盖凸条共用同一矩阵。
        for (snap=snap_bump_matrix)
            place_snap_bump(
                snap=snap,
                inset=lower_lip_wall,
                z_pos=base_height + lip_h / 2
            );
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
    difference() {
        union() {
            difference() {
                union() {
                    // 上盖顶板。
                    translate([0, 0, lid_height - top_t - epsilon])
                        cuboid(
                            [box_width, box_length, top_t + epsilon],
                            rounding=corner_r,
                            edges="Z",
                            anchor=BOT
                        );

                    // 上盖侧壁。
                    rect_tube(
                        size=[box_width, box_length],
                        wall=wall,
                        h=lid_height - top_t + epsilon,
                        rounding=corner_r,
                        anchor=BOT
                    );
                }

                // 让掉外圈，留下能插入下盒唇边内侧的薄壁。
                translate([0, 0, -epsilon])
                    rect_tube(
                        size=[box_width, box_length],
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

        // 顶盖蜂窝散热区，避开按键端。
        honeycomb_vents();
    }
}


// 一体式可按压机构：顶面圆形按压舌片 + 根部带斜面加强圆台的内侧触点柱。
// 触点柱先按常见 DevKit 按键高度预留，后续应根据实物板微调长度。
module button_actuators() {
    pad_y = -20;
    root_head_bottom = button_plunger_top_z - button_root_head_h;

    for (x=[-8.5, 8.5]) {
        // 顶面不再额外凸起，圆形舌片本身就是手指按压面。
        // 触点末端保持细圆柱和平底。
        translate([x, pad_y, button_plunger_bottom_z])
            cylinder(
                h=root_head_bottom - button_plunger_bottom_z + epsilon,
                d=2.6,
                $fn=32
            );

        // 喇叭形圆台移到连接根部：靠顶盖宽，朝触点柱方向逐渐收窄。
        translate([x, pad_y, root_head_bottom])
            underside_button_root();
    }
}


module underside_button_root() {
    rotate_extrude(convexity=4, $fn=64)
        polygon(points=[
            [0,    0],
            [1.30, 0],
            [1.55, 0.27],
            [1.95, 0.95],
            [2.05, 1.25],
            [2.05, 1.45],
            [0,    1.45]
        ]);
}


module button_flexure_cuts() {
    pad_y = -20;
    cut_w = 0.8;
    ring_outer_d = 7.0;
    ring_inner_d = ring_outer_d - 2 * cut_w;
    tongue_half_w = 2.6;
    slot_end_y = -10.5;
    cut_z = lid_height - top_t - 2 * epsilon;
    cut_h = top_t + 4 * epsilon;

    for (x=[-8.5, 8.5]) {
        translate([x, pad_y, cut_z])
            linear_extrude(height=cut_h)
                difference() {
                    difference() {
                        circle(d=ring_outer_d, $fn=64);
                        circle(d=ring_inner_d, $fn=64);
                    }

                    // 在 +Y 方向保留桥接，让圆头与悬臂相连。
                    translate([-tongue_half_w, 0])
                        square([2 * tongue_half_w, ring_outer_d]);
                }

        // 两条圆头长缝形成可弯曲舌片。
        for (side=[-1, 1])
            hull() {
                translate([
                    x + side * (ring_outer_d / 2 - cut_w / 2),
                    // 从圆环左右切点开始，确保长缝与圆缝充分重叠、平滑贯通。
                    pad_y,
                    cut_z
                ]) cylinder(h=cut_h, d=cut_w, $fn=20);

                translate([
                    x + side * (ring_outer_d / 2 - cut_w / 2),
                    slot_end_y,
                    cut_z
                ]) cylinder(h=cut_h, d=cut_w, $fn=20);
            }
    }
}


module honeycomb_vents() {
    vent_d = 4.1;
    pitch_x = 5.4;
    pitch_y = 4.7;

    for (row=[-3:3], col=[-2:2]) {
        x = col * pitch_x + ((row % 2) == 0 ? 0 : pitch_x / 2);
        y = 7 + row * pitch_y;

        // 圆角边界内只保留中央区域的孔。
        if (abs(x) < 13 && y > -9 && y < 23)
            translate([x, y, lid_height - top_t - epsilon])
                cylinder(h=top_t + 2 * epsilon, d=vent_d, $fn=6);
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
            translate([0, 0, base_height]) lid_shell();
        if ($preview) pcb_preview();
    }
    else if (layout == "print") {
        if (part == "both" || part == "base")
            translate([-(box_width / 2 + 5), 0, 0]) base_shell();

        if (part == "both" || part == "lid")
            translate([box_width / 2 + 5, 0, lid_height])
                rotate([180, 0, 0]) lid_shell();
    }
    else {
        // 打开视图：下盒在左，盖子翻开后放在右侧，便于检查内部结构。
        if (part == "both" || part == "base") {
            translate([-(box_width / 2 + 7), 0, 0]) base_shell();
            if ($preview)
                translate([-(box_width / 2 + 7), 0, 0]) pcb_preview();
        }

        if (part == "both" || part == "lid")
            // 外表面朝上展示；整体抬高，使内侧触点柱不会穿过展示平面。
            translate([
                box_width / 2 + 7,
                0,
                max(0, -button_plunger_bottom_z)
            ]) lid_shell();
    }
}

show_model();
