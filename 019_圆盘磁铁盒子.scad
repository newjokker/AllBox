include <BOSL2/std.scad>

// 圆柱总高度，单位 mm
box_height = 75;            // [10:1:160]

// 磁铁规格表：["型号", 实际直径, 需要孔径, 孔中心到圆心距离]
// 增加规格时只需要在这里加一行，下面用型号选择规格。
magnet_specs = [
    ["10mm",    10,     10.30,  17],
    ["6mm",     6,      6.30,   17.6],
    ["5mm",     5,      5.30,   18.0],
    ["4mm",     4,      4.30,   18.3],
    ["3.5mm",   3.5,    3.8,    18.6],
    ["3mm",     3,      3.3,    18.7],
    ["2.5mm",   2.5,    2.8,    18.9],
];

// 磁铁使用列表：每一行是 [型号, 数量]
// 例如 ["6mm", 8] 表示使用 8 个 6mm 磁铁。
magnet_groups = [
    // ["10mm", 1],
    // ["6mm", 8],
    // ["5mm", 5],
    ["4mm", 4],
    ["3.5mm", 4],
    ["3mm", 4],
    ["2.5mm", 3]
];


/* [孔位排布 / Hole Layout] */
// 相邻磁铁孔之间的角度，单位度
// hole_angle_step = 24;       // [5:1:45]
hole_angle_step = 24;       // [5:1:45]

/* [渲染 / Render] */
// 显示实际磁铁直径在孔里的状态
show_actual_magnets = true; // [false, true]

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

function spec_index_by_name(name, index=0) =
    index >= len(magnet_specs) ? undef :
    magnet_specs[index][0] == name ? index :
    spec_index_by_name(name, index + 1);

function spec_row_by_name(name) =
    let(index = spec_index_by_name(name))
    assert(index != undef, str("magnet_groups 中的 ", name, " 没有写入 magnet_specs"))
    magnet_specs[index];

function group_count(group) =
    assert(group[1] >= 0, "magnet_groups 中的数量不能小于 0")
    group[1];
function group_name(group) = group[0];
function group_start_angle(index) =
    index <= 0 ? 0 :
    group_start_angle(index - 1) + group_count(magnet_groups[index - 1]) * hole_angle_step;

function spec_actual_diameter(spec) = spec[1];
function spec_hole_diameter(spec) = spec[2];
function spec_center_radius(spec) = spec[3];
function spec_hole_radius(spec) = spec_hole_diameter(spec) / 2;
function spec_actual_radius(spec) = spec_actual_diameter(spec) / 2;

module magnet_ring(count, start_angle, radius, center_radius, height=h) {
    if (count > 0)
        for (i = [0:count - 1]) {
            rotate([0, 0, start_angle + i * hole_angle_step])
                translate([center_radius, 0, thick])
                    cylinder(r=radius, h=height);
        }
}

module magnet_group_rings(show_actual=false) {
    if (len(magnet_groups) > 0)
        for (group_index = [0:len(magnet_groups) - 1])
            let(
                group = magnet_groups[group_index],
                spec = spec_row_by_name(group_name(group))
            )
            magnet_ring(
                group_count(group),
                group_start_angle(group_index),
                show_actual ? spec_actual_radius(spec) : spec_hole_radius(spec),
                spec_center_radius(spec),
                show_actual ? h - thick : h
            );
}

difference() {
    cylinder(r=outer_radius, h=h);

    // 中心空腔。
    translate([0, 0, thick])
        cylinder(r=inner_radius, h=h);

    // 磁铁孔。
    magnet_group_rings();
}

if (show_actual_magnets) {
    color([0.1, 0.45, 1.0, 0.45])
        magnet_group_rings(true);
}
