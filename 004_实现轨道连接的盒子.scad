include <BOSL2/std.scad>

$fn = 96;

// 上盖尺寸
upper_box_size = [50, 100, 8];

// 下半盒体尺寸
lower_box_size = [upper_box_size.x, upper_box_size.y, 24];

// 预览时上盖沿 Y 方向拉开的距离，0 表示完全合上
slide_open_distance = 42;  // [0:2:90]

// 四周墙壁的厚度
wall_thickness = 2;        // [1.5:0.2:3.5]

// 盒子底盖的厚度
bottom_thickness = 1.2;    // [0.8, 1.0, 1.2, 1.4, 1.6]

// 盒子转角的弧度
rounding = 8;              // [3:1:15]

// 上盖厚度
lid_thickness = 2;         // [1.2:0.2:4]

// 上盖边缘向下包住盒口的裙边高度
lid_skirt_height = 4;      // [2:0.5:8]

// 滑轨与燕尾槽的装配间隙
rail_slop = 0.25;          // [0.1:0.05:0.6]

// 上盖插入下盒内侧的避让间隙
lid_insert_slop = 0.35;    // [0.1:0.05:0.8]

// 燕尾轨向侧面伸出的深度
rail_depth = 3;            // [2:0.5:6]

// 燕尾轨入口处的高度
rail_neck_height = 3.4;    // [2:0.2:6]

// 燕尾轨里面较宽处的高度，用于防止上盖向上脱出
rail_back_height = 5.2;    // [3:0.2:8]

// 下盒内侧承载燕尾槽的轨道座厚度
rail_seat_depth = 8;       // [5:0.5:12]

// 下盒内侧承载燕尾槽的轨道座高度
rail_seat_height = 6;      // [4:0.5:10]

// 轨道前后两端避让，让盖子更容易插入
rail_end_clearance = 6;    // [2:1:12]

// 入口导角长度
lead_in_length = 8;        // [3:1:16]


function rail_length(size_y) = size_y - rail_end_clearance * 2;

function rail_z_center() =
    lower_box_size.z - rail_seat_height / 2;

function rail_x_center(side) =
    side * (lower_box_size.x / 2 - wall_thickness - rail_seat_depth / 2);

function lid_insert_size() = [
    upper_box_size.x - wall_thickness * 2 - rail_seat_depth * 2 - lid_insert_slop * 2,
    upper_box_size.y - wall_thickness * 2 - lid_insert_slop * 2
];

function rail_inner_x(side) =
    side * lid_insert_size().x / 2;


// 沿 Y 方向延伸、向侧面咬合的燕尾截面。
// neck_height 是靠盒子中心一侧的窄口，back_height 是侧壁里更宽的一侧。
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


module lower_slide_seat(side=1) {
    seat_len = rail_length(lower_box_size.y);

    difference() {
        translate([rail_x_center(side), 0, rail_z_center()])
            cuboid(
                [rail_seat_depth, seat_len, rail_seat_height],
                anchor=CENTER
            );

        // 燕尾槽侧向切入轨道座，稍微放大给打印和滑动留间隙。
        translate([
            rail_inner_x(side),
            0,
            rail_z_center()
        ])
            side_dovetail_prism_y(
                length=seat_len + 0.02,
                neck_height=rail_neck_height + rail_slop,
                back_height=rail_back_height + rail_slop,
                depth=rail_depth + rail_slop,
                side=side
            );
    }
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

        lower_slide_seat(1);
        lower_slide_seat(-1);
    }
}


module lid_shell() {
    union() {
        cuboid(
            [upper_box_size.x, upper_box_size.y, lid_thickness],
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


module lid_rail(side=1) {
    translate([
        rail_inner_x(side),
        0,
        rail_z_center() - lower_box_size.z
    ])
        side_dovetail_prism_y(
            length=rail_length(upper_box_size.y),
            neck_height=rail_neck_height,
            back_height=rail_back_height,
            depth=rail_depth,
            side=side
        );
}


module upper_lid() {
    union() {
        lid_shell();
        lid_rail(1);
        lid_rail(-1);
    }
}


// ---------------- 主体预览 ----------------

lower_box();

translate([0, slide_open_distance, lower_box_size.z])
    upper_lid();
