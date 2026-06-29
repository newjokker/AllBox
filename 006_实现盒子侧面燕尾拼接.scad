include <BOSL2/std.scad>

$fn = 96;

// 单个盒子的外部尺寸
box_size = [58, 72, 24];

// 预览时两个盒子沿 X 方向拉开的距离，0 表示拼接到位
pair_open_distance = 18;   // [0:2:50]

// 四周墙壁的厚度
wall_thickness = 2;        // [1.5:0.2:3.5]

// 盒子底盖的厚度
bottom_thickness = 1.4;    // [0.8, 1.0, 1.2, 1.4, 1.6]

// 盒子转角的弧度
rounding = 7;              // [3:1:15]

// 燕尾拼接件沿盒子深度方向的长度
dovetail_length = 42;      // [20:2:70]

// 燕尾轨窄口高度
dovetail_neck_height = 4;  // [2:0.2:8]

// 燕尾轨内侧宽端高度
dovetail_back_height = 7;  // [3:0.2:12]

// 燕尾轨向外伸出的深度
dovetail_depth = 4;        // [2:0.2:8]

// 凹槽块在侧面凸出的厚度
receiver_depth = 8;        // [5:0.5:14]

// 凹槽块高度
receiver_height = 11;      // [7:0.5:18]

// 凹槽和凸轨之间的装配间隙
dovetail_slop = 0.35;      // [0.1:0.05:0.8]

// 燕尾连接件中心离盒底的高度
connector_z = 12;          // [6:1:30]


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


// 沿 Y 方向延伸、向侧面咬合的燕尾截面。
// side=1 表示向 +X 伸出，side=-1 表示向 -X 伸出。
module side_dovetail_prism_y(
    length,
    neck_height,
    back_height,
    depth,
    side=1
) {
    polyhedron(
        points=[
            [0,            -length / 2, -neck_height / 2],
            [0,            -length / 2,  neck_height / 2],
            [side * depth, -length / 2,  back_height / 2],
            [side * depth, -length / 2, -back_height / 2],
            [0,             length / 2, -neck_height / 2],
            [0,             length / 2,  neck_height / 2],
            [side * depth,  length / 2,  back_height / 2],
            [side * depth,  length / 2, -back_height / 2]
        ],
        faces=[
            [0, 1, 2, 3],
            [4, 7, 6, 5],
            [0, 4, 5, 1],
            [1, 5, 6, 2],
            [2, 6, 7, 3],
            [3, 7, 4, 0]
        ]
    );
}


module side_dovetail_rail(side=1) {
    translate([
        side * box_size.x / 2,
        0,
        connector_z
    ])
        side_dovetail_prism_y(
            length=dovetail_length,
            neck_height=dovetail_neck_height,
            back_height=dovetail_back_height,
            depth=dovetail_depth,
            side=side
        );
}


module side_dovetail_receiver(side=-1) {
    block_center_x = side * (box_size.x / 2 + receiver_depth / 2);

    difference() {
        translate([block_center_x, 0, connector_z])
            cuboid(
                [receiver_depth, dovetail_length + 8, receiver_height],
                rounding=1,
                edges="Y",
                anchor=CENTER
            );

        translate([side * box_size.x / 2, 0, connector_z])
            side_dovetail_prism_y(
                length=dovetail_length + 0.02,
                neck_height=dovetail_neck_height + dovetail_slop,
                back_height=dovetail_back_height + dovetail_slop,
                depth=receiver_depth + dovetail_slop,
                side=side
            );
    }
}


module plain_box() {
    rounded_open_box(
        outer_size=[box_size.x, box_size.y],
        box_height=box_size.z,
        wall=wall_thickness,
        bottom_t=bottom_thickness,
        corner_r=rounding
    );
}


module male_box() {
    union() {
        plain_box();
        side_dovetail_rail(1);
    }
}


module female_box() {
    union() {
        plain_box();
        side_dovetail_receiver(-1);
    }
}


// ---------------- 主体预览 ----------------

translate([-box_size.x / 2 - pair_open_distance / 2, 0, 0])
    male_box();

translate([box_size.x / 2 + pair_open_distance / 2, 0, 0])
    female_box();
