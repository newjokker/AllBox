include <BOSL2/std.scad>

$fn = 96;

// 上盖尺寸
upper_box_size = [70, 100, 8];

// 下半盒体尺寸
lower_box_size = [upper_box_size.x, upper_box_size.y, 26];

// 预览时上盖沿 Y 方向拉开的距离，0 表示完全合上
open_distance = 38;        // [0:2:90]

// 四周墙壁的厚度
wall_thickness = 2;        // [1.5:0.2:3.5]

// 盒子底盖的厚度
bottom_thickness = 1.4;    // [0.8, 1.0, 1.2, 1.4, 1.6]

// 盒子转角的弧度
rounding = 8;              // [3:1:15]

// 上盖边缘向下包住盒口的裙边高度
lid_skirt_height = 4;      // [2:0.5:8]

// 上盖插入下盒内侧的避让间隙
lid_insert_slop = 0.35;    // [0.1:0.05:0.8]

// 螺丝柱外径
screw_post_diameter = 8;   // [5:0.5:12]

// 螺丝孔直径，M3 自攻或机牙螺丝可从 3.0 到 3.3 开始试
screw_hole_diameter = 3.2; // [2:0.1:5]

// 上盖沉头/螺丝头避让孔直径
screw_head_diameter = 6.4; // [4:0.2:10]

// 上盖沉头/螺丝头避让孔深度
screw_head_depth = 2.2;    // [1:0.2:5]

// 螺丝孔深度
screw_depth = 18;          // [6:1:40]

// 螺丝柱距离盒子内侧边的距离
screw_post_inset = 10;     // [6:1:22]

// 螺丝柱连接到侧壁的加强筋厚度
rib_thickness = 2;         // [1:0.2:4]


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


module screw_post(height, hole_depth=screw_depth) {
    difference() {
        cylinder(d=screw_post_diameter, h=height, anchor=BOT);

        translate([0, 0, height - hole_depth])
            cylinder(
                d=screw_hole_diameter,
                h=hole_depth + 0.02,
                anchor=BOT
            );
    }
}


module post_ribs(pos, height) {
    sx = pos.x > 0 ? 1 : -1;
    sy = pos.y > 0 ? 1 : -1;
    rib_h = min(height, 12);
    rib_overlap = 0.7;
    rib_x_len = max(
        lower_box_size.x / 2
        - wall_thickness
        - abs(pos.x)
        - screw_post_diameter / 2
        + rib_overlap * 2,
        0
    );
    rib_y_len = max(
        lower_box_size.y / 2
        - wall_thickness
        - abs(pos.y)
        - screw_post_diameter / 2
        + rib_overlap * 2,
        0
    );

    translate([
        pos.x + sx * (screw_post_diameter / 2 - rib_overlap + rib_x_len / 2),
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
        pos.y + sy * (screw_post_diameter / 2 - rib_overlap + rib_y_len / 2),
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
        rounded_open_box(
            outer_size=[lower_box_size.x, lower_box_size.y],
            box_height=lower_box_size.z,
            wall=wall_thickness,
            bottom_t=bottom_thickness,
            corner_r=rounding
        );

        for (p = post_positions(lower_box_size)) {
            translate([p.x, p.y, bottom_thickness])
                screw_post(lower_box_size.z - bottom_thickness);

            post_ribs(p, lower_box_size.z - bottom_thickness);
        }
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


module screw_head_cut(total_height) {
    union() {
        translate([0, 0, -0.01])
            cylinder(
                d=screw_hole_diameter + 0.35,
                h=total_height + 0.02,
                anchor=BOT
            );

        translate([0, 0, total_height - screw_head_depth])
            cylinder(
                d=screw_head_diameter,
                h=screw_head_depth + 0.02,
                anchor=BOT
            );
    }
}


module upper_lid() {
    lid_total_height = bottom_thickness;

    difference() {
        lid_shell();

        for (p = post_positions(lower_box_size))
            translate([p.x, p.y, 0])
                screw_head_cut(lid_total_height);
    }
}


// ---------------- 主体预览 ----------------

lower_box();

translate([0, open_distance, lower_box_size.z])
    upper_lid();
