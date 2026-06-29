$fn = 64;


// ============================================================
// 参数读取函数
// ============================================================
function get_param(params, key) =
    let (matches = [for (p = params) if (p[0] == key) p[1]])
        len(matches) == 1
            ? matches[0]
            : assert(false, str("parameter '", key, "' not found"));

function screw_param(screw_size, field) =
    get_param(screw_boss_params, str(screw_size, ".", field));


// ============================================================
// 螺丝柱参数表
//
// pilot_d : 自攻螺丝底孔直径
// boss_d  : 螺丝柱主体外径
// foot_d  : 底部加强脚外径，当前版本不直接决定 foot 外径
// foot_h  : 底部加强脚高度
// entry_d : 螺丝孔入口倒角最大直径
// entry_h : 螺丝孔入口倒角高度
// ============================================================
screw_boss_params = [
    // M2
    ["m2.pilot_d", 1.6],
    ["m2.boss_d", 3.8],
    ["m2.foot_d", 6.5],
    ["m2.foot_h", 2.4],
    ["m2.entry_d", 2.4],
    ["m2.entry_h", 0.8],

    // M2.5
    ["m2_5.pilot_d", 2.0],
    ["m2_5.boss_d", 4.8],
    ["m2_5.foot_d", 7.5],
    ["m2_5.foot_h", 2.6],
    ["m2_5.entry_d", 3.0],
    ["m2_5.entry_h", 0.9],

    // M3
    ["m3.pilot_d", 2.5],
    ["m3.boss_d", 5.6],
    ["m3.foot_d", 9.0],
    ["m3.foot_h", 3.2],
    ["m3.entry_d", 3.8],
    ["m3.entry_h", 1.0],

    // M4
    ["m4.pilot_d", 3.3],
    ["m4.boss_d", 7.2],
    ["m4.foot_d", 11.5],
    ["m4.foot_h", 4.0],
    ["m4.entry_d", 5.0],
    ["m4.entry_h", 1.2],

    // M5
    ["m5.pilot_d", 4.2],
    ["m5.boss_d", 9.0],
    ["m5.foot_d", 14.0],
    ["m5.foot_h", 4.8],
    ["m5.entry_d", 6.2],
    ["m5.entry_h", 1.4]
];


// ============================================================
// 螺丝柱脚
//
// 这是你原来喜欢的版本：
// 先生成一个大圆柱，再用 rotate_extrude 切掉一个圆弧，
// 形成底部外扩、顶部圆滑收回的加强脚。
//
// column_r : 上面螺丝柱底部半径
// foot_h   : 圆滑过渡高度
// ============================================================
module standoff_foot(column_r, foot_h) {
    if (foot_h > 0) {
        difference() {
            cylinder(
                h = foot_h,
                r = column_r + foot_h
            );

            translate([0, 0, foot_h])
                rotate_extrude(angle = 360)
                    translate([column_r + foot_h, 0, 0])
                        circle(r = foot_h);
        }
    }
}


// ============================================================
// 螺丝柱主体
//
// boss_h        : 螺丝柱总高度
// screw_size    : "m2" / "m2_5" / "m3" / "m4" / "m5"
// pilot_h       : 螺丝底孔深度
// tapered       : 主柱是否轻微锥形
// taper_ratio   : 主柱底部放大倍率
// entry_chamfer : 是否开启孔口倒角
// eps           : 布尔运算防重合量
// ============================================================
module screw_boss(
    boss_h = 10,
    screw_size = "m3",
    pilot_h = 6,
    tapered = true,
    taper_ratio = 1.08,
    entry_chamfer = true,
    eps = 0.01
) {
    pilot_d = screw_param(screw_size, "pilot_d");
    boss_d  = screw_param(screw_size, "boss_d");
    foot_h  = screw_param(screw_size, "foot_h");
    entry_d = screw_param(screw_size, "entry_d");
    entry_h = screw_param(screw_size, "entry_h");

    pilot_r = pilot_d / 2;
    boss_r  = boss_d / 2;
    entry_r = entry_d / 2;

    column_bottom_r = tapered ? boss_r * taper_ratio : boss_r;
    column_top_r    = boss_r;

    assert(boss_h > foot_h, "boss_h must be larger than foot_h");
    assert(pilot_h > 0, "pilot_h must be > 0");
    assert(pilot_h <= boss_h, "pilot_h must be <= boss_h");
    assert(entry_h >= 0, "entry_h must be >= 0");
    assert(entry_h <= pilot_h, "entry_h must be <= pilot_h");
    assert(entry_r < column_top_r, "entry_d must be smaller than boss_d");
    assert(pilot_r < column_top_r, "pilot_d must be smaller than boss_d");

    difference() {
        union() {
            // 底部圆滑加强脚
            standoff_foot(
                column_r = column_bottom_r,
                foot_h = foot_h
            );

            // 主螺丝柱
            translate([0, 0, foot_h])
                cylinder(
                    h = boss_h - foot_h,
                    r1 = column_bottom_r,
                    r2 = column_top_r
                );
        }

        // 螺丝底孔：从顶部向下打孔
        translate([0, 0, boss_h - pilot_h - eps])
            cylinder(
                h = pilot_h + 2 * eps,
                r = pilot_r
            );

        // 孔底圆头，减少应力集中
        translate([0, 0, boss_h - pilot_h])
            sphere(r = pilot_r);

        // 顶部入口倒角，方便螺丝导入
        if (entry_chamfer && entry_h > 0) {
            translate([0, 0, boss_h - entry_h])
                cylinder(
                    h = entry_h + eps,
                    r1 = pilot_r,
                    r2 = entry_r
                );
        }
    }
}


// ============================================================
// 兼容旧接口
// ============================================================
module ScrewBoss(
    height_all = 10,
    type = "m3",
    hole_height = 6,
    taper = true,
    chamfer = true
) {
    screw_boss(
        boss_h = height_all,
        screw_size = type,
        pilot_h = hole_height,
        tapered = taper,
        entry_chamfer = chamfer
    );
}



translate([0 * 18, 0, 0])
    screw_boss(boss_h = 20, screw_size = "m3", pilot_h = 6);




