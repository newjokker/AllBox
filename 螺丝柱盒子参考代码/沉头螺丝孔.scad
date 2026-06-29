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
// hole_h     : 螺丝杆通孔深度
// screw_size : "m2" / "m2_5" / "m3" / "m4" / "m5"
// through    : 是否做成贯穿孔
// eps        : 布尔运算防重合量
//
// 注意：
// 这个模块是“减材体”，要放在 difference() 里面使用。
// 默认从 z=0 开始，向下挖孔。
// z=0 是外表面，也就是沉头大圆开口所在平面。
// ============================================================
module countersink_hole(
    hole_h = 8,
    screw_size = "m3",
    through = false,
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
        // 顶部大，底部小
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

        // 3. 如果想确保贯穿，可以额外向下延长
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
// Demo：在一个板子上挖沉头螺丝孔
// ============================================================
module countersink_hole_demo() {
    plate_w = 24;
    plate_d = 24;
    plate_h = 6;

    difference() {
        // 测试板
        translate([0, 0, -plate_h])
            cube([plate_w, plate_d, plate_h], center = true);

        // 沉头螺丝孔
        // z=0 是上表面
        countersink_hole(
            hole_h = plate_h + 2,
            screw_size = "m3",
            through = true
        );
    }
}

translate([1 * 30, 0, 0])
    difference() {
        translate([0, 0, 0])
            cylinder(r=2.5, h=5);

        countersink_hole(
            hole_h = 8,
            screw_size = "m2",
            through = true
        );
    }







