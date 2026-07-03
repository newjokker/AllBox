include <BOSL2/std.scad>

/* [模型尺寸 / Cabinet Size] */
// 柜体外宽，单位 mm
cabinet_width = 100;        // [60:1:200]
// 柜体外深，单位 mm
cabinet_depth = 105;        // [40:1:200]
// 单层开口柜体高度，单位 mm
open_shell_height = 100;    // [40:1:200]
// 上下叠放段的单段高度，单位 mm
stack_shell_height = 99;    // [40:1:200]

/* [盒体结构 / Shell] */
// 壁厚，单位 mm
wall_thickness = 1.5;       // [1:0.1:5]
// 圆角半径，单位 mm
corner_radius = 20;         // [2:1:40]

/* [展示 / Preview] */
// 展示方式
preview_mode = "both";      // [both, open_shell, stack_shell]
// 两个预览件之间的间距，单位 mm
preview_gap = 20;           // [0:1:80]
// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 96;      // [48, 64, 96, 128]

/* [Hidden] */
$fn = model_resolution;

// 为避免圆角超过柜体尺寸，实际圆角会按外形尺寸自动限制。
usable_corner_radius = min(corner_radius, cabinet_width / 2 - 0.1, cabinet_depth - 0.1);

// 原始 A 模块：生成一个前侧开口、顶部和侧边圆角的柜体。
module rounded_open_shell(
    wall=1.5,
    width=150,
    depth=105,
    height=298,
    radius=10
) {
    difference() {
        // 外部实体：保留原始模型的 Y 向圆角风格。
        cuboid(
            [width, depth, height],
            anchor=BOT,
            rounding=radius,
            edges="Y",
            except=[BOTTOM]
        );

        // 内部挖空：前侧保留开口，背面保留一层厚度。
        translate([0, wall, wall])
            cuboid(
                [width - 2 * wall, depth - wall, height - 2 * wall],
                anchor=BOT,
                rounding=radius,
                edges="Y",
                except=[BOTTOM]
            );
    }
}

// 原始 B 模块：生成一段圆角外罩，并在上方叠放一个同尺寸开口柜体。
module stacked_round_shell(
    wall=1.5,
    width=150,
    depth=105,
    height=198,
    radius=10
) {
    difference() {
        cuboid([width, depth, height], anchor=BOT, edges="Y", except=[BOTTOM]);
        cuboid(
            [width, depth, height],
            anchor=BOT,
            rounding=radius,
            edges="Y",
            except=[BOTTOM]
        );
    }

    translate([0, 0, height])
        rounded_open_shell(
            wall=wall,
            width=width,
            depth=depth,
            height=height,
            radius=radius
        );
}

module show_open_shell() {
    rounded_open_shell(
        wall=wall_thickness,
        width=cabinet_width,
        depth=cabinet_depth,
        height=open_shell_height,
        radius=usable_corner_radius
    );
}

module show_stack_shell() {
    stacked_round_shell(
        wall=wall_thickness,
        width=cabinet_width,
        depth=cabinet_depth,
        height=stack_shell_height,
        radius=usable_corner_radius
    );
}

if (preview_mode == "open_shell") {
    show_open_shell();
} else if (preview_mode == "stack_shell") {
    show_stack_shell();
} else {
    translate([-(cabinet_width + preview_gap) / 2, 0, 0])
        show_open_shell();

    translate([(cabinet_width + preview_gap) / 2, 0, 0])
        show_stack_shell();
}
