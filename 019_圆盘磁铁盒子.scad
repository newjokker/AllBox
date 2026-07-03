include <BOSL2/std.scad>

// 圆柱总高度，单位 mm
box_height = 75;            // [10:1:160]

/* [孔位排布 / Hole Layout] */
// 相邻磁铁孔之间的角度，单位度
hole_angle_step = 24;       // [5:1:45]

/* [A 类磁铁孔 / Magnet A] */
// A 类磁铁孔数量
hole_count_a = 8;          // [0:1:30]
// A 类磁铁孔半径，单位 mm
hole_radius_a = 3.15;       // [0.5:0.05:8]
// A 类磁铁孔中心到圆心的距离，单位 mm
hole_center_radius_a = 17.6; // [0:0.1:60]

/* [B 类磁铁孔 / Magnet B] */
// B 类磁铁孔数量
hole_count_b =5;           // [0:1:30]
// B 类磁铁孔半径，单位 mm
hole_radius_b = 2.65;       // [0.5:0.05:8]
// B 类磁铁孔中心到圆心的距离，单位 mm
hole_center_radius_b = 18;  // [0:0.1:60]

/* [C 类磁铁孔 / Magnet C] */
// C 类磁铁孔数量，设为 0 可关闭
hole_count_c = 2;           // [0:1:30]
// C 类磁铁孔半径，单位 mm
hole_radius_c = 2.15;       // [0.5:0.05:8]
// C 类磁铁孔中心到圆心的距离，单位 mm
hole_center_radius_c = 18.3; // [0:0.1:60]

/* [渲染 / Render] */
// 圆弧细分数量，越高越圆但生成越慢
model_resolution = 256;     // [64, 96, 128, 192, 256]

/* [Hidden] */
$fn = model_resolution;

/* [模型尺寸 / Box Size] */
// 圆柱外半径，单位 mm
outer_radius = 20;          // [10:0.5:60]

// 中心空腔半径，单位 mm
inner_radius = 11;          // [0:0.5:50]
// 底部保留厚度，单位 mm
bottom_thickness = 2;       // [0.5:0.1:10]


h = box_height;
thick = bottom_thickness;
hole_start_angle_a = 0;
hole_start_angle_b = hole_count_a * hole_angle_step;
hole_start_angle_c = (hole_count_a + hole_count_b) * hole_angle_step;

module magnet_hole_ring(count, start_angle, hole_radius, center_radius) {
    if (count > 0)
        for (i = [0:count - 1]) {
            rotate([0, 0, start_angle + i * hole_angle_step])
                translate([center_radius, 0, thick])
                    cylinder(r=hole_radius, h=h);
        }
}

difference() {
    cylinder(r=outer_radius, h=h);

    // 中心空腔。
    translate([0, 0, thick])
        cylinder(r=inner_radius, h=h);

    // A 类磁铁
    magnet_hole_ring(hole_count_a, hole_start_angle_a, hole_radius_a, hole_center_radius_a);

    // B 类磁铁
    magnet_hole_ring(hole_count_b, hole_start_angle_b, hole_radius_b, hole_center_radius_b);

    // C 类磁铁
    magnet_hole_ring(hole_count_c, hole_start_angle_c, hole_radius_c, hole_center_radius_c);
}
