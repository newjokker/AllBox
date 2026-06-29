include <BOSL2/std.scad>

$fn = 64;


// ============================================================
// 参数读取函数
// ============================================================
function get_param(params, key) =
    let (matches = [for (p = params) if (p[0] == key) p[1]])
        len(matches) == 1
            ? matches[0]
            : assert(false, str("parameter '", key, "' not found"));

function countersink_param(screw_size, field) =
    get_param(countersink_hole_params, str(screw_size, ".", field));


// ============================================================
// 沉头螺丝孔参数表
//
// shaft_clearance_d : 螺丝杆通过孔直径，通常比螺丝外径略大
// countersink_d     : 沉头大端直径
// countersink_depth : 沉头锥形高度
// countersink_angle : 沉头角度，常见 90 度
// ============================================================
countersink_hole_params = [
    // M2
    ["m2.shaft_clearance_d", 2.3],
    ["m2.countersink_d", 4.4],
    ["m2.countersink_depth", 1.1],
    ["m2.countersink_angle", 90],

    // M2.5
    ["m2_5.shaft_clearance_d", 2.8],
    ["m2_5.countersink_d", 5.5],
    ["m2_5.countersink_depth", 1.35],
    ["m2_5.countersink_angle", 90],

    // M3
    ["m3.shaft_clearance_d", 3.4],
    ["m3.countersink_d", 6.5],
    ["m3.countersink_depth", 1.55],
    ["m3.countersink_angle", 90],

    // M4
    ["m4.shaft_clearance_d", 4.5],
    ["m4.countersink_d", 8.5],
    ["m4.countersink_depth", 2.0],
    ["m4.countersink_angle", 90],

    // M5
    ["m5.shaft_clearance_d", 5.5],
    ["m5.countersink_d", 10.5],
    ["m5.countersink_depth", 2.5],
    ["m5.countersink_angle", 90]
];


// ============================================================
// 沉头螺丝孔，减材模块
//
// 默认：
// z = 0 是上表面
// 向下挖孔
// ============================================================
module countersink_hole(
    hole_depth = 8,
    screw_size = "m3",
    through = true,
    epsilon = 0.01
) {
    shaft_clearance_d = countersink_param(screw_size, "shaft_clearance_d");
    countersink_d     = countersink_param(screw_size, "countersink_d");
    countersink_depth = countersink_param(screw_size, "countersink_depth");

    shaft_clearance_r = shaft_clearance_d / 2;
    countersink_r     = countersink_d / 2;

    assert(hole_depth > 0, "hole_depth must be > 0");
    assert(countersink_depth > 0, "countersink_depth must be > 0");
    assert(countersink_d > shaft_clearance_d, "countersink_d must be larger than shaft_clearance_d");
    assert(hole_depth >= countersink_depth, "hole_depth must be >= countersink_depth");

    union() {
        // 1. 沉头锥形孔
        translate([0, 0, -countersink_depth - epsilon])
            cylinder(
                h = countersink_depth + 2 * epsilon,
                r1 = shaft_clearance_r,
                r2 = countersink_r
            );

        // 2. 螺丝杆通过孔
        translate([0, 0, -hole_depth - epsilon])
            cylinder(
                h = hole_depth - countersink_depth + 2 * epsilon,
                r = shaft_clearance_r
            );

        // 3. 贯穿保险
        if (through) {
            translate([0, 0, -hole_depth - 100])
                cylinder(
                    h = 100 + epsilon,
                    r = shaft_clearance_r
                );
        }
    }
}


// ============================================================
// 沉头螺丝孔实体模块
//
// 这个模块直接生成：
// 外面圆柱 + 内部沉头孔 + 顶部凸缘
//
// body_height          : 外圆柱高度
// screw_size           : "m2" / "m2_5" / "m3" / "m4" / "m5"
// outer_diameter_scale : 外圆柱直径 = countersink_d * outer_diameter_scale
// rim_height           : 顶部凸缘高度
// through              : 是否贯穿
//
// 默认：
// z = 0 是上表面
// 圆柱向下生成
// ============================================================
module countersink_part(
    body_height = 10,
    screw_size = "m3",
    outer_diameter_scale = 2,
    through = true,
    rim_height = 1,
    epsilon = 0.01
) {
    countersink_d = countersink_param(screw_size, "countersink_d");

    outer_d = countersink_d * outer_diameter_scale;
    outer_r = outer_d / 2;
    countersink_r = countersink_d / 2;

    assert(body_height > 0, "body_height must be > 0");
    assert(rim_height >= 0, "rim_height must be >= 0");
    assert(outer_diameter_scale > 1, "outer_diameter_scale should be > 1");

    translate([0, 0, body_height]) {

        // 顶部凸缘，中心开出沉头大端直径的孔
        if (rim_height > 0) {
            difference() {
                cylinder(
                    r = outer_r,
                    h = rim_height
                );

                translate([0, 0, -epsilon])
                    cylinder(
                        r = countersink_r,
                        h = rim_height + 2 * epsilon
                    );
            }
        }

        // 主体圆柱 + 内部沉头孔
        difference() {
            cylinder(
                r = outer_r,
                h = body_height,
                anchor = [0, 0, 1]
            );

            countersink_hole(
                hole_depth = body_height + epsilon,
                screw_size = screw_size,
                through = through,
                epsilon = epsilon
            );
        }
    }
}


// ============================================================
// 示例
// ============================================================
countersink_part(
    body_height = 4,
    screw_size = "m3",
    outer_diameter_scale = 1.3,
    rim_height = 3
);