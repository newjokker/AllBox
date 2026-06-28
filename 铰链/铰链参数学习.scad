include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn = 64;

// 全局装配间隙，会影响数值型 pin_diam 的孔径
$slop = 0.10;


// ----------------------
// 参数区
// ----------------------
hinge_len       = 45;      // length：铰链总长度
hinge_segs      = 9;       // segs：铰链分段数，建议奇数
hinge_offset    = 5.5;     // offset：安装面到铰链轴心的距离
hinge_gap       = 0.25;    // gap：每节铰链之间的间隙
hinge_seg_ratio = 0.75;    // seg_ratio：inner 段和 outer 段的长度比例

knuckle_d       = 6;       // knuckle_diam：铰链圆筒外径
pin_d           = 4.6;     // pin_diam：一体打印锥体底部直径；普通铰链时是销孔直径

leaf_gap        = 0.40;    // 两片叶片之间的间隙
leaf_thick      = 2.2;      // 
leaf_w          = 20;


// ----------------------
// 铰链半边模块
// inner=false：外侧铰链节
// inner=true ：内侧铰链节
// ----------------------
module demo_knuckle_hinge(inner=false)
{
    knuckle_hinge(
        // ---- 位置参数 ----
        length = hinge_len,          // 铰链总长度
        segs = hinge_segs,           // 铰链节数量
        offset = 4,       // 铰链轴心相对安装点的偏移
        inner = inner,               // 是否生成互补的内侧铰链节

        // ---- 支撑臂参数 ----
        arm_height = 1.2,            // 垂直支撑臂高度
        arm_angle = 45,              // 斜支撑臂角度，0~90
        fill = true,                 // 填充支撑臂与安装面之间的三角区域
        clear_top = false,           // 是否切掉超过安装面的上部材料
        clip = undef,                // 裁切铰链支撑区域；这里不裁切

        // ---- 分段和间隙 ----
        gap = 0.25,             // 铰链节之间的间隙
        seg_ratio = hinge_seg_ratio, // 内外节长度比例

        // ---- 圆筒和销轴/一体打印参数 ----
        knuckle_diam = 6,    // 铰链圆筒外径
        pin_diam = 3,            // 普通铰链为销孔直径；in_place 时为锥体底部直径
        pin_fn = 24,                 // 销孔/锥体相关圆形细分数
        teardrop = UP,               // 普通销孔可做水滴孔；这里也显式写出
        in_place = 20,               // 一体打印铰链；数字表示锥体角度，true 等价于 45

        // ---- 圆角过渡 ----
        round_top = 0.25,            // 上部连接处圆滑过渡
        round_bot = 0.45,            // 下部连接处圆滑过渡

        // ---- 螺丝销轴相关参数 ----
        // 注意：这几个参数主要用于 pin_diam="M3" 或 "#6" 这种普通螺丝销轴模式。
        // 当前例子用了 in_place，所以它们会被接受，但实际不会作为螺丝孔生效。
        tap_depth = 8,               // 自攻孔深度限制
        screw_head = "socket",       // 螺丝头类型
        screw_tolerance = "close",   // 螺丝孔公差

        // ---- 避让参数 ----
        clearance = leaf_gap / 2,    // 抬高/偏移旋转中心，减少叶片干涉
        knuckle_clearance = 0,       // 给对侧铰链节避让；需要 diff()，这里先设 0

        // ---- BOSL2 attachable 参数 ----
        anchor = BOTTOM,             // 锚点
        spin = 0,                    // 绕 Z 轴旋转
        orient = UP                  // 朝向
    );
}


// ----------------------
// 生成一个完整的一体打印铰链
// ----------------------
module hinge_assembly()
{
    // 左叶片 + 外侧铰链节
    color("gold")
    cuboid(
        [leaf_w, hinge_len, leaf_thick],
        rounding = 2,
        edges = [LEFT+FRONT, LEFT+BACK],
        anchor = TOP
    ) {
        position(TOP + RIGHT)
            orient(UP, -90)
                demo_knuckle_hinge(inner=false);
    }

    // 右叶片 + 内侧铰链节
    color("lightgreen")
    right(leaf_w + leaf_gap)
    cuboid(
        [leaf_w, hinge_len, leaf_thick],
        rounding = 2,
        edges = [RIGHT+FRONT, RIGHT+BACK],
        anchor = TOP
    ) {
        position(TOP + LEFT)
            orient(UP, 90)
                demo_knuckle_hinge(inner=true);
    }
}


hinge_assembly();