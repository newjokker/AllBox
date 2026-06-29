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
module countersink_hole_mask(
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
// 沉头座安装避让槽，减材模块
//
// 这个模块用于在上方薄板中切出一个圆孔，
// 让下面的沉头座顶部环形凸缘可以露出来。
//
// 默认：
// z = 0 是板子下表面附近
// 向上切
// ============================================================
module countersink_mount_cut_mask(
    screw_size = "m3",
    cut_depth = 10,
    clearance = 0,
    epsilon = 0.01
) {
    countersink_d = countersink_param(screw_size, "countersink_d");

    cut_r = countersink_d / 2 + clearance;

    translate([0, 0, -epsilon])
        cylinder(
            r = cut_r,
            h = cut_depth + 2 * epsilon
        );
}


// ============================================================
// 沉头螺丝孔实体模块
//
// 这个模块直接生成：
// 1. 外面圆柱主体
// 2. 内部沉头孔
// 3. 顶部环形凸缘
//
// 注意：
// 顶部凸起不是整个圆柱，
// 而是一个外半径 outer_r、内半径 countersink_r 的环。
//
// 默认：
// z = 0 是实体底面
// 向上生成
// ============================================================
module countersink_mount_part(
    body_height = 10,
    screw_size = "m3",
    outer_diameter_scale = 2,
    rim_height = 1,
    through = true,
    epsilon = 0.01
) {
    countersink_d = countersink_param(screw_size, "countersink_d");

    outer_d = countersink_d * outer_diameter_scale;
    outer_r = outer_d / 2;

    countersink_r = countersink_d / 2;

    assert(body_height > 0, "body_height must be > 0");
    assert(rim_height >= 0, "rim_height must be >= 0");
    assert(outer_diameter_scale > 1, "outer_diameter_scale should be > 1");

    union() {
        // ----------------------------------------------------
        // 1. 主体圆柱 + 内部沉头孔
        // ----------------------------------------------------
        difference() {
            cylinder(
                r = outer_r,
                h = body_height
            );

            // 从主体顶面向下挖沉头孔
            translate([0, 0, body_height])
                countersink_hole_mask(
                    hole_depth = body_height + epsilon,
                    screw_size = screw_size,
                    through = through,
                    epsilon = epsilon
                );
        }

        // ----------------------------------------------------
        // 2. 顶部环形凸缘
        //
        // 这里是一个圈：
        // 外半径 = outer_r
        // 内半径 = countersink_r
        // 高度   = rim_height
        // ----------------------------------------------------
        if (rim_height > 0) {
            translate([0, 0, body_height])
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
    }
}


// ============================================================
// 示例
// ============================================================

difference() {
    // 上方薄板
    cuboid([50, 30, 1], anchor=[0, 0, -1]);

    // 在薄板上切出避让孔
    // 这个孔对应顶部那个环中间的空位
    countersink_mount_cut_mask(
        screw_size = "m4",
        cut_depth = 12,
        clearance = 0
    );
}


// 下方添加沉头座实体
translate([0, 0, -4])
    countersink_mount_part(
        body_height = 2,
        screw_size = "m4",
        outer_diameter_scale = 1.3,
        rim_height = 2,
        through = true
    );