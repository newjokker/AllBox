include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn = 64;


// 两个盒盖/叶片之间的间隙
// 也就是左右两个板子中间留出的缝
leaf_gap = 0.4;

// 铰链每一节之间的间隙
// 比如铰链是 7 节，那么节与节之间要留一点空隙
seg_gap = 0.2;


// 自定义一个铰链模块
// inner 参数用来控制当前这一半铰链是“内侧节”还是“外侧节”
//
// inner = false：生成一侧铰链叶片
// inner = true ：生成另一侧与它互补的铰链叶片
module myhinge(inner)
    knuckle_hinge(
        length = 25,           // 铰链总长度，沿 Y 方向
        segs = 7,              // 铰链分成 7 节
        offset = 2.1,          // 铰链轴心相对安装面的偏移量
        inner = inner,         // 是否生成内侧铰链节
        in_place = true,       // 两半铰链按装配位置直接生成，而不是分开生成
        clearance = leaf_gap/2,// 铰链两半之间的装配间隙
        round_bot = 0.5,       // 铰链底部圆角
        gap = seg_gap,         // 铰链节之间的间隙
        seg_ratio = 1          // 每节铰链占用比例，影响节的宽度
    );


// 生成左边这一块板子
// 尺寸：[X方向宽度, Y方向长度, Z方向厚度]
// 这里是 20 x 25 x 5
cuboid(
    [20,25,1],

    rounding = 7,

    // 只给左前、左后两条竖边做圆角
    // LEFT+FWD  = 左前边
    // LEFT+BACK = 左后边
    edges = [LEFT+FWD, LEFT+BACK]
)
{
    // 在当前 cuboid 的 TOP+RIGHT 位置放置一个铰链
    // TOP+RIGHT 表示：板子的顶部 + 右侧
    position(TOP+RIGHT)

        // 调整铰链方向
        // orient(UP,-90) 把铰链旋转到合适的安装方向
        orient(UP,-90)

            // false 外侧，true：内侧
            myhinge(false);


    // align(RIGHT) 表示接下来生成的物体和当前物体右侧对齐
    // right(leaf_gap) 表示向右移动 leaf_gap，也就是两个板子之间留 0.4mm 间隙
    align(RIGHT)
    right(leaf_gap)

        // 生成右边这一块板子
        cuboid(
            [20,25,1],

            // 圆角半径 7
            rounding = 7,

            // 只给右前、右后两条竖边做圆角
            // 这样左右两块板子的外侧是圆角，中间连接处不是圆角
            edges = [RIGHT+FWD, RIGHT+BACK]
        )

            // 在右边板子的 TOP+LEFT 位置放置另一半铰链
            // TOP+LEFT 表示：板子的顶部 + 左侧
            position(TOP+LEFT)

                // 把这一半铰链旋转到和左边铰链相对的位置
                orient(UP,90)

                    // 生成右边板子上的另一半铰链
                    // true 表示生成与 false 互补的铰链节
                    myhinge(true);
}