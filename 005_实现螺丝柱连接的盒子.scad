include <BOSL2/std.scad>
use <螺丝柱盒子参考代码/螺丝柱.scad>
use <螺丝柱盒子参考代码/沉头螺丝孔.scad>

$fn = 96;

// 预览模式
preview_mode = "open"; // [√, cutaway]

// 上盖平面尺寸
upper_box_size = [70, 100];

// 下半盒体尺寸
lower_box_size = [upper_box_size.x, upper_box_size.y, 26];

// 预览时上盖沿 Y 方向拉开的距离，0 表示完全合上
open_distance = 38;        // [0:2:190]

// 四周墙壁的厚度
wall_thickness = 1;        // [1.5:0.2:3.5]

// 盒子底盖的厚度
bottom_thickness = 1;    // [0.8, 1.0, 1.2, 1.4, 1.6]

// 盒子转角的弧度
rounding = 8;              // [3:1:15]

// 上盖边缘向下包住盒口的裙边高度
lid_skirt_height = 2;      // [2:0.5:8]

// 上盖插入下盒内侧的避让间隙
lid_insert_slop = 0.2;    // [0.1:0.05:0.8]

// 螺丝规格
screw_size = "m3";         // [m2, m2_5, m3, m4, m5]

// 螺丝底孔深度
screw_pilot_depth = 14;    // [4:1:28]

// 盖子下方沉头座主体高度
lid_countersink_body_height = 2; // [1.2:0.2:6]

// 盖子下方沉头座顶部环形凸缘高度
lid_countersink_rim_height = 1.2;  // [0.4:0.2:3]

// 沉头座外径相对沉头孔大端直径的比例
lid_countersink_outer_scale = 1.2; // [1.1:0.05:2]

// 下盒螺丝柱与上盖沉头座底面的装配间隙
screw_stack_clearance = 0.25;       // [0:0.05:1]

// 螺丝柱是否轻微锥形，打印时底部更结实
screw_post_taper = true;   // [true, false]

// 螺丝柱距离盒子内侧边的距离
screw_post_inset = 10;     // [6:1:22]

// 螺丝柱连接到侧壁的加强筋厚度
rib_thickness = 1;         // [1:0.2:4]

// 螺丝柱连接到侧壁的加强筋高度
rib_height = 8;           // [4:1:18]


function screw_boss_outer_d(type) =
    type == "m2"   ? 3.8 :
    type == "m2_5" ? 4.8 :
    type == "m3"   ? 5.6 :
    type == "m4"   ? 7.2 :
    type == "m5"   ? 9.0 :
    assert(false, str("unsupported screw_size: ", type));

function screw_boss_foot_h(type) =
    type == "m2"   ? 2.4 :
    type == "m2_5" ? 2.6 :
    type == "m3"   ? 3.2 :
    type == "m4"   ? 4.0 :
    type == "m5"   ? 4.8 :
    assert(false, str("unsupported screw_size: ", type));

function lid_insert_size() = [
    upper_box_size.x - wall_thickness * 2 - lid_insert_slop * 2,
    upper_box_size.y - wall_thickness * 2 - lid_insert_slop * 2
];

function post_positions(size) = [
    [ size.x / 2 - screw_post_inset,  size.y / 2 - screw_post_inset],
    [-size.x / 2 + screw_post_inset,  size.y / 2 - screw_post_inset],
    [ size.x / 2 - screw_post_inset, -size.y / 2 + screw_post_inset],
    [-size.x / 2 + screw_post_inset, -size.y / 2 + screw_post_inset]
];

function lid_mount_total_height() =
    lid_countersink_body_height + lid_countersink_rim_height;

function resolved_post_height() =
    let (
        h = lower_box_size.z
            - bottom_thickness
            - lid_mount_total_height()
            - screw_stack_clearance
    )
    assert(
        h > screw_boss_foot_h(screw_size),
        "lower_box_size.z is too small for the calculated lower screw boss height"
    )
    h;

function resolved_pilot_depth() =
    min(screw_pilot_depth, resolved_post_height() - 0.2);

module rounded_open_box(
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


module lower_screw_post() {
    screw_boss(
        boss_h = resolved_post_height(),
        screw_size = screw_size,
        pilot_h = resolved_pilot_depth(),
        tapered = screw_post_taper,
        entry_chamfer = true
    );
}


module post_ribs(pos, height) {
    sx = pos.x > 0 ? 1 : -1;
    sy = pos.y > 0 ? 1 : -1;
    boss_d = screw_boss_outer_d(screw_size);
    rib_h = min(height, rib_height);
    rib_overlap = 0.7;
    rib_x_len = max(
        lower_box_size.x / 2
        - wall_thickness
        - abs(pos.x)
        - boss_d / 2
        + rib_overlap * 2,
        0
    );
    rib_y_len = max(
        lower_box_size.y / 2
        - wall_thickness
        - abs(pos.y)
        - boss_d / 2
        + rib_overlap * 2,
        0
    );

    translate([
        pos.x + sx * (boss_d / 2 - rib_overlap + rib_x_len / 2),
        pos.y,
        bottom_thickness
    ])
        cuboid(
            [
                rib_x_len,
                rib_thickness,
                rib_h
            ],
            anchor=BOT
        );

    translate([
        pos.x,
        pos.y + sy * (boss_d / 2 - rib_overlap + rib_y_len / 2),
        bottom_thickness
    ])
        cuboid(
            [
                rib_thickness,
                rib_y_len,
                rib_h
            ],
            anchor=BOT
        );
}


module lower_box() {
    union() {
        lower_box_shell();
        lower_screw_posts();
    }
}


module lower_box_shell() {
    rounded_open_box(
        outer_size=[lower_box_size.x, lower_box_size.y],
        box_height=lower_box_size.z,
        wall=wall_thickness,
        bottom_t=bottom_thickness,
        corner_r=rounding
    );
}


module lower_screw_posts() {
    for (p = post_positions(lower_box_size)) {
        translate([p.x, p.y, bottom_thickness])
            lower_screw_post();

        post_ribs(p, resolved_post_height());
    }
}


module open_preview() {
    lower_box();

    translate([0, open_distance, lower_box_size.z])
        upper_lid();
}


module closed_assembly_view() {
    lower_box();

    translate([0, 0, lower_box_size.z])
        upper_lid();
}


module cutaway_preview() {
    intersection() {
        closed_assembly_view();

        translate([
            lower_box_size.x / 4,
            0,
            lower_box_size.z / 2
        ])
            cuboid(
                [
                    lower_box_size.x / 2,
                    lower_box_size.y + 20,
                    lower_box_size.z * 2
                ],
                anchor=CENTER
            );
    }
}


module lid_shell() {
    union() {
        cuboid(
            [upper_box_size.x, upper_box_size.y, bottom_thickness],
            rounding=rounding,
            edges="Z",
            anchor=BOT
        );

        translate([0, 0, -lid_skirt_height])
            rect_tube(
                size=lid_insert_size(),
                wall=wall_thickness,
                h=lid_skirt_height,
                rounding=max(rounding - wall_thickness - lid_insert_slop, 1),
                anchor=BOT
            );
    }
}


module lid_screw_cut() {
    // countersink_mount_cut_mask 的约定：z=0 是板子下表面，向上切。
    countersink_mount_cut_mask(
        screw_size = screw_size,
        cut_depth = bottom_thickness + 0.02
    );
}


module lid_countersink_mount() {
    translate([0, 0, -lid_mount_total_height()])
        countersink_mount_part(
            body_height = lid_countersink_body_height,
            screw_size = screw_size,
            outer_diameter_scale = lid_countersink_outer_scale,
            rim_height = lid_countersink_rim_height,
            through = true
        );
}


module upper_lid() {
    union() {
        difference() {
            lid_shell();

            for (p = post_positions(lower_box_size))
                translate([p.x, p.y, 0])
                    lid_screw_cut();
        }

        for (p = post_positions(lower_box_size))
            translate([p.x, p.y, 0])
                lid_countersink_mount();
    }
}


// ---------------- 主体预览 ----------------

if (preview_mode == "cutaway")
    cutaway_preview();
else
    open_preview();
