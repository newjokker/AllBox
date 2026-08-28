include <BOSL2/std.scad>

/*
 * ESP32 DevKit 卡扣盒（第一版）
 *
 * 目标：先得到可运行、可打印、容易继续修改的基础结构。
 * - 下盒底部两排长孔让排针向下露出
 * - 前端开 USB 孔
 * - 上盖两个一体式悬臂按键机构
 * - 上盖蜂窝散热孔
 * - 上下盖沿用 001_实现卡扣链接的盒子.scad 的唇边 + 摩擦凸点结构
 *
 * 默认按常见 ESP32 DevKit（约 51 x 28 mm）预留空间。
 */

/* [显示] */
// 选择生成的零件：both=上下盒都显示，base=只显示下盒，lid=只显示上盖。
part = "both";              // [both,base,lid]

// 显示方式：open=打开并排，assembly=闭合装配，print=按打印方向并排摆放。
layout = "print";            // [open,assembly,print]

// ESP32 参考板，仅用于预览和定位，不参与导出实体。
pcb_size = [20.57, 45.22, 1.6];

/* [基础尺寸] */
// 盒子内部净宽，沿 X 方向，单位 mm；外宽会自动加上左右两侧壁厚。
box_width = pcb_size[0] + 0.5;
// 盒子内部净长，沿 Y 方向，单位 mm；外长会自动加上前后两侧壁厚。
box_length = pcb_size[1] + 0.5;
// 下盒内部净高，单位 mm；从底板内表面到卡扣唇边起点，不包含底板和唇边。
base_height = 6;
// 上盖总高度，单位 mm；从盖子开口端计算到顶面。
lid_height = 4;

/* [上下盖配合] */
// 上下盖唇边的单侧配合间隙，单位 mm；越小越紧，建议按打印机在 0.08~0.25 之间调整。
fit_gap = 0.08; // 在测试
// fit_gap = 0.12; // 稍微有点松

/* [Type-C开口] */
// 是否生成矩阵中定义的 Type-C 开口。
typec_enabled = true;          // [true,false]
// [所在面, 水平位置, 孔底到盒内底板上表面的距离, 宽度, 高度, 圆角, 切割深度]。
typec_cutout_matrix = [
    ["front", 0, 1.5, 11, 4, 1.4, 4]
];

/* [额外矩形出口] */
// 六面矩形出口；侧面格式和 top/bottom 格式参见公共内核说明。
side_rect_cutout_matrix = [];
side_rect_cutout_depth = 4;

/* [卡扣凹凸条] */
// 卡扣矩阵，每行格式：[所在面, 沿该面的中心位置, 条形长度]。
// left/right 面的位置沿 Y 方向；front/back 面的位置沿 X 方向，单位均为 mm。
// 增删矩阵行即可改变卡扣个数；同一矩阵同时生成下盒凹槽和上盖凸条。
snap_bump_matrix = [
    ["right", -12, 7.6],
    ["right",  12, 7.6],
    ["left",  -12, 7.6],
    ["left",   12, 7.6],
    ["front",  0, 7.6],
    ["back",  0, 7.6]
];

/* [底部排针] */
// 排针矩阵，每行格式：[X位置, Y位置, 底部开槽长度]，单位 mm。
pin_length = 37;  // 这个只能在真实长度上增加 0.5mm
pin_row_matrix = [
    [-17.4/2, -(box_length - pin_length)/2 + 1.38, pin_length],
    [ 17.4/2, -(box_length - pin_length)/2 + 1.38, pin_length]
];
// 每排排针开槽的宽度，单位 mm。
// pin_slot_width = 2.8;
pin_slot_width = 3;

// 排针伸出盒子底面以下的长度，单位 mm；主要影响装配预览。
pin_exposed_length = 2;

/* [PCB托台] */
// 托台矩阵，每行格式：[X位置, Y位置, X方向大小, Y方向大小, 高度]，单位 mm。
// 增删矩阵行即可改变托台个数；PCB 预览高度采用矩阵中的最大托台高度。
pcb_support_matrix = [
    // [-9, -23.5, 3, 3, 0.1],
    // [-9,  23.5, 3, 3, 0.1],
    // [ 9, -23.5, 3, 3, 0.1],
    // [ 9,  23.5, 3, 3, 0.1]
];

/* [按压触点] */
// 按键矩阵，每行格式：[X位置, Y位置, 弹片方向角度, 下方触点伸出长度]。
// 矩阵行数就是按键数量；角度 0 表示弹片从按压圆头朝 +Y 方向延伸。
button_matrix = [
    [-4.18/2, -(box_length/2 - 17.47), 180, 3.5],
    [ 4.18/2, -(box_length/2 - 17.47), 180, 3.5]
];
// 圆形按压舌片外径，单位 mm。
button_pad_diameter = 4;
// 从圆形按压头中心到弹片固定端的长度，单位 mm。
button_flexure_length = 11.5;
// 弹片主体宽度，单位 mm。
button_flexure_width = 3.2;
// 围绕弹片切开的缝隙宽度，单位 mm。
button_slot_width = 0.4;
// 盖内按压触点细杆直径，单位 mm。
button_plunger_diameter = 2.6;
// 触点柱根部斜面加强圆台的最大直径和高度，单位 mm。
button_root_diameter = 3.1;
button_root_height = 1.45;

/* [上盖PCB固定柱] */
// [X, Y, 柱径, 向下长度, 根部直径, 根部高度]。
lid_fix_post_matrix = [];
lid_fix_post_vent_clearance = 1;

/* [蜂窝镂空] */
// 是否生成顶盖蜂窝散热孔。
vent_enabled = true;          // [true,false]
// false 保留原来的固定区域蜂窝；true 自动铺满上盖并避让部件。
vent_auto_fill = false;       // [true,false]
// 蜂窝区域中心位置 [X, Y]，单位 mm。
vent_center = [0, 10];
// 蜂窝孔行数和列数；相邻行自动错开半个横向间距。
vent_rows = 4;
vent_columns = 5;
// 单个六边形孔的对角直径，单位 mm。
vent_hole_diameter = 3.3;
// 蜂窝孔中心间距 [横向间距, 纵向间距]，单位 mm。
vent_pitch = [4, 4.8];
// 允许生成孔中心的区域大小 [X宽度, Y长度]，超出区域的孔会被省略。
vent_area_size = [32, 32];
vent_edge_clearance = 1;
button_vent_clearance = 1;
top_cutout_vent_clearance = 1;

/* [Hidden] */
wall = 2;
bottom_t = 1.6;
top_t = 1.6;
corner_r = 2;
lip_h = 2.4;
epsilon = 0.04;
$fn = 64;


// 公共函数、校验和实体结构统一放在共享内核中。
include <esp32_shell_core.scad>

show_model();
