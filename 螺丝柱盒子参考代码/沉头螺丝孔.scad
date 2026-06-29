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
// clearance_d : 螺丝杆通过孔直径，通常比螺丝外径略大
// head_d      : 沉头大端直径
// head_h      : 沉头锥形高度
// angle       : 沉头角度，常见 90 度
// ============================================================
countersink_hole_params = [
    // M2
    ["m2.clearance_d", 2.3],
    ["m2.head_d", 4.4],
    ["m2.head_h", 1.1],
    ["m2.angle", 90],

    // M2.5
    ["m2_5.clearance_d", 2.8],
    ["m2_5.head_d", 5.5],
    ["m2_5.head_h", 1.35],
    ["m2_5.angle", 90],

    // M3
    ["m3.clearance_d", 3.4],
    ["m3.head_d", 6.5],
    ["m3.head_h", 1.55],
    ["m3.angle", 90],

    // M4
    ["m4.clearance_d", 4.5],
    ["m4.head_d", 8.5],
    ["m4.head_h", 2.0],
    ["m4.angle", 90],

    // M5
    ["m5.clearance_d", 5.5],
    ["m5.head_d", 10.5],
    ["m5.head_h", 2.5],
    ["m5.angle", 90]
];


// ============================================================
// 沉头螺丝孔，减材模块
//
// 默认：
// z = 0 是上表面
// 向下挖孔
// ============================================================
module countersink_hole(
    hole_h = 8,
    screw_size = "m3",
    through = true,
    eps = 0.01
) {
    clearance_d = countersink_param(screw_size, "clearance_d");
    head_d      = countersink_param(screw_size, "head_d");
    head_h      = countersink_param(screw_size, "head_h");

    clearance_r = clearance_d / 2;
    head_r      = head_d / 2;

    assert(hole_h > 0, "hole_h must be > 0");
    assert(head_h > 0, "head_h must be > 0");
    assert(head_d > clearance_d, "head_d must be larger than clearance_d");
    assert(hole_h >= head_h, "hole_h must be >= head_h");

    union() {
        // 1. 沉头锥形孔
        translate([0, 0, -head_h - eps])
            cylinder(
                h = head_h + 2 * eps,
                r1 = clearance_r,
                r2 = head_r
            );

        // 2. 螺丝杆通过孔
        translate([0, 0, -hole_h - eps])
            cylinder(
                h = hole_h - head_h + 2 * eps,
                r = clearance_r
            );

        // 3. 贯穿保险
        if (through) {
            translate([0, 0, -hole_h - 100])
                cylinder(
                    h = 100 + eps,
                    r = clearance_r
                );
        }
    }
}


// ============================================================
// 沉头螺丝孔实体模块
//
// 这个模块直接生成：
// 外面圆柱 + 内部沉头孔
//
// body_h        : 外圆柱高度
// screw_size    : "m2" / "m2_5" / "m3" / "m4" / "m5"
// outer_d_scale : 外圆柱直径 = head_d * outer_d_scale
// through       : 是否贯穿
// eps           : 布尔运算防重合量
//
// 默认：
// z = 0 是上表面
// 圆柱向下生成
// ============================================================
module countersink_part(
    body_h = 10,
    screw_size = "m3",
    outer_d_scale = 2,
    through = true,
    extra_hight=1
) {
    eps = 0.01;

    translate([0, 0, body_h]){
        head_d = countersink_param(screw_size, "head_d");

        outer_d = head_d * outer_d_scale;
        outer_r = outer_d / 2;

        difference(){
            cylinder(r=outer_d/2, h=extra_hight);
            translate([0, 0, -eps])
                cylinder(r=head_d/2, h=extra_hight + eps*2);
        }

        assert(body_h > 0, "body_h must be > 0");
        assert(outer_d_scale > 1, "outer_d_scale should be > 1");

        difference() {
            // 外面的圆柱
            cylinder(
                r = outer_r,
                h = body_h,
                anchor = [0, 0, 1]
            );

            // 内部沉头孔
            countersink_hole(
                hole_h = body_h + eps,
                screw_size = screw_size,
                through = through,
                eps = eps
            );
        }

    }


}


countersink_part(
    body_h = 4,
    screw_size = "m3",
    outer_d_scale = 1.3,
    extra_hight=3
);
