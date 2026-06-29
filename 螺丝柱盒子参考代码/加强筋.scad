
include <BOSL2/std.scad>

$fn = 128;

// 盒体内侧竖向加强筋。
// 每道筋都是从底板向上长出的直板，平面垂直于 XOY；
// X/Z 和 Y/Z 两组互相垂直，避免顶部悬空结构。
module box_inner_rect_tube_ribs(
    outer_size=[100, 50],
    box_height=30,
    wall=1,
    bottom_t=1,
    rib_t=1,
    rib_count_x=2,
    rib_count_y=2,
    top_clearance=3
) {
    inner_size = [
        outer_size.x - wall * 2,
        outer_size.y - wall * 2
    ];
    rib_z_size = box_height - bottom_t - top_clearance;

    if (rib_z_size > 0) {
        for (i = [1:rib_count_y]) {
            y = -inner_size.y / 2 + inner_size.y * i / (rib_count_y + 1);

            translate([0, y, bottom_t])
                cuboid(
                    [inner_size.x, rib_t, rib_z_size],
                    anchor=BOT
                );
        }

        for (i = [1:rib_count_x]) {
            x = -inner_size.x / 2 + inner_size.x * i / (rib_count_x + 1);

            translate([x, 0, bottom_t])
                cuboid(
                    [rib_t, inner_size.y, rib_z_size],
                    anchor=BOT
                );
        }
    }
}
