include <BOSL2/std.scad>
include <BOSL2/walls.scad>

$fn = 64;


// ============================================================
// 蜂窝板框架盒子
//
// length  : X 方向长度
// width   : Y 方向宽度
// height  : Z 方向高度
// thick   : 板厚
//
// strut   : 蜂窝筋宽
// spacing : 蜂窝间距
// frame   : 外框宽度
//
// show_top    : 是否生成顶部
// show_bottom : 是否生成底部
// show_front  : 是否生成前侧
// show_back   : 是否生成后侧
// show_left   : 是否生成左侧
// show_right  : 是否生成右侧
// ============================================================
module hex_box_frame(
    length=50,
    width=40,
    height=30,
    thick=1,

    strut=0.5,
    spacing=3,
    frame=1,

    show_top=true,
    show_bottom=false,
    show_front=true,
    show_back=true,
    show_left=true,
    show_right=true
){

    // -------------------------
    // 前后侧板，位于 Y 方向
    // -------------------------
    if (show_front)
        translate([0, -width/2 + thick/2, 0])
            rotate([90, 0, 0])
                hex_panel(
                    [length, height, thick],
                    strut=strut,
                    spacing=spacing,
                    frame=frame,
                    anchor=CENTER
                );

    if (show_back)
        translate([0, width/2 - thick/2, 0])
            rotate([90, 0, 0])
                hex_panel(
                    [length, height, thick],
                    strut=strut,
                    spacing=spacing,
                    frame=frame,
                    anchor=CENTER
                );


    // -------------------------
    // 左右侧板，位于 X 方向
    // -------------------------
    if (show_left)
        translate([-length/2 + thick/2, 0, 0])
            rotate([0, 90, 0])
                hex_panel(
                    [height, width, thick],
                    strut=strut,
                    spacing=spacing,
                    frame=frame,
                    anchor=CENTER
                );

    if (show_right)
        translate([length/2 - thick/2, 0, 0])
            rotate([0, 90, 0])
                hex_panel(
                    [height, width, thick],
                    strut=strut,
                    spacing=spacing,
                    frame=frame,
                    anchor=CENTER
                );


    // -------------------------
    // 顶板，位于 Z 方向
    // -------------------------
    if (show_top)
        translate([0, 0, height/2 - thick/2])
            hex_panel(
                [length, width, thick],
                strut=strut,
                spacing=spacing,
                frame=frame,
                anchor=CENTER
            );


    // -------------------------
    // 底板，位于 Z 方向
    // -------------------------
    if (show_bottom)
        translate([0, 0, -height/2 + thick/2])
            hex_panel(
                [length, width, thick],
                strut=strut,
                spacing=spacing,
                frame=frame,
                anchor=CENTER
            );
}


// ============================================================
// 示例调用
// ============================================================
hex_box_frame(
    length=50,
    width=40,
    height=80,
    thick=1,

    strut=0.5,
    spacing=5,
    frame=2,

    show_top=false,
    show_bottom=true
);