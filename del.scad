include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn = 64;

// 两个盒子之间的间隙
leaf_gap = 0.8;

// 铰链每节之间的间隙
seg_gap = 0.4;


// ----------------------
// 铰链模块
// ----------------------
module myhinge(inner)
    knuckle_hinge(
        length = 30,            // 铰链沿 Y 方向长度
        segs = 7,               // 铰链分成 7 节
        offset = 4,             // 铰链轴心离安装面的距离
        inner = inner,          // 两半铰链是否互补
        in_place = true,        // 按装配位置生成
        clearance = leaf_gap/2, // 铰链两半之间间隙
        round_bot = 0.5,
        gap = seg_gap,
        seg_ratio = 1,
        clear_top=true,
        arm_angle=30,
    );


// ----------------------
// 左盒子
// ----------------------
cuboid([30, 30, 1], anchor=CENTER)
{
    // 左盒子的右上边安装铰链
    position(DOWN + RIGHT)
        orient(UP, -90)
            myhinge(false);


    // ----------------------
    // 右盒子
    // ----------------------
    align(RIGHT)
    right(leaf_gap)
        cuboid([30, 30, 1], anchor=CENTER)
        {
            // 右盒子的左上边安装另一半铰链
            position(DOWN + LEFT)
                orient(UP, 90)
                    myhinge(true);
        }

}

rotate([180, 0, 0]) 
    difference(){
        cuboid([30, 30, 5], anchor=[0, 0, -1]);
        translate([0.5, 0, 0]) 
            cuboid([29, 28, 5], anchor=[0, 0, -1]);
    }

rotate([180, 0, 0]) 
    translate([30 + leaf_gap, 0, 0]) 
        difference(){
            cuboid([30, 30, 5], anchor=[0, 0, -1]);
            cuboid([28, 28, 5], anchor=[0, 0, -1]);
            translate([-15, 0, 0]) 
                cuboid([4, 30, 5], anchor=[0, 0, -1]);
        }