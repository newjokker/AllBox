include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn = 128;

// 上半盒子的尺寸
upper_box_size = [50, 90, 10];

// 下半盒体尺寸
lower_box_size = [50, 90, 45];

// 盒盖打开的角度
open_angle = 180;           // [0:10:180]

// 四周墙壁的厚度，因为有 lip 和 FrictionBump 需要稍微厚一点
wall_thickness = 2;         // [1.5:0.2:3.5]

// 盒子底盖的厚度
bottom_thickness = 1.2;     // [0.8, 1.0, 1.2, 1.4, 1.6]     

// 盒子转角的弧度
rounding = 8;               // [3:1:15]

// 唇边的高度
lip_height = 2;             // [1:0.5:3]

// 这边名字要往上一下，现在 index 不好分辨
lip_width_index_upper   = 0.5;      // 
lip_width_index_down    = 0.55;     // 

// 铰链的长度
hinge_length = upper_box_size.y * 3/4;          // 

// 铰链节的个数
hinge_seg = 9;              // [3:2:15]

// 上下铰链长度的比例
hinge_seg_ratio = 1;        // [0.3:0.1:2]

// 凸起销钉孔，以在安装面的边缘处形成间隙
hinge_clearance = 0.35;  

// 铰链节之间的间隙，当铰链大小不变化的时候，一般固定即可，设置不合理会导致太松或者太紧
hinge_gap = 0.25; 

// 铰链与盒子的附着面的加上的长度，一般为 0 即可，觉得不够牢可以适当增加
hinge_arm_base_height = 1;

// 当盒子上下不一样高的时候，这个参数可以增加矮盒子那边铰链的长度使得能链接共面的矮半边
hinge_arm_extra_height = abs(lower_box_size.z - upper_box_size.z) / 2;

// 摩擦凹凸点正面凸点个数
N = 6;              // [1:1:8]

// 摩擦凹凸点侧面凸点的个数
M = 2;              // [1:1:8]

// 摩擦凹凸点凸点的长度
fb_length = 2;      // [1:0.5:4]

// 摩擦凹凸点凸点两端的球的半径
fb_r = 0.8;         // [0.4:0.1:2]

// 手指防滑线的长度
fht_length = 20;    // [5:3:30]

// 手指防滑线的两端半球的半径
fht_r = 0.4;        // [0.4:0.2:1.2]

// 手指防滑线的个数
fht_T = 4;          // [2:1:8]

// 手指防滑线围绕手指槽向下延伸的高度
fht_zone_extra = 8; // [0:1:20]

// 手指槽上边的长度
fn_upper_length = 10;

// 手指槽下边的长度
fn_down_lenght = 20;

// 手指槽的高度
fn_h = 5;

// 手指槽的厚度，目前没用，为了切割前面的手指防滑线
fn_thick = 1.5;

// 手指槽附近需要避开的摩擦凸点余量
fn_bump_clearance = 0.6; // [0:0.1:2]

// 铰链底座的厚度，一般不需要调整
hinge_offset = 2.2;

// 绿色上盖铰链的单独高度微调。正数表示在 open_angle=180 平放预览时，把绿色铰链向上提。
upper_hinge_z_lift = lower_box_size.z - 10;

// 铰链轴心距离盒子中心的 X 距离
hinge_axis_x = lower_box_size.x / 2 + hinge_offset;

// 铰链轴放在高度差的中点，180 度展开时两半盒子的外表面会共面，上下高度不一致时，闭合基准仍在 lip 处；
hinge_axis_z = (upper_box_size.z - lower_box_size.z) / 2;

// 高度不一致时，铰链的安装臂需要多伸出一段去够到共同轴线。
// 如果预览里连接臂还不够长，可以只调大 hinge_arm_extra_height。
hinge_arm_height = hinge_arm_base_height + hinge_arm_extra_height;

// 手指槽在 Y 方向影响到的半宽。落在这个范围里的匹配凸点会显得残缺或多余。
function FingerNotchHalfWidth() =
    max(fn_upper_length, fn_down_lenght) / 2 + fb_length / 2 + fb_r + fn_bump_clearance;

function FingerNotchAffectsBump(y_pos) =
    abs(y_pos) <= FingerNotchHalfWidth();

// 防滑线只排在手指槽附近，避免上下盒高度不同造成整高均分后视觉不一致。
function FingerGripZoneHeight(height) =
    min(height - 2 * fht_r, max(fn_h, fn_h + fht_zone_extra));

function FingerGripZoneBottom(height) =
    max(
        fht_r,
        min(
            height - fht_r - FingerGripZoneHeight(height),
            height - fn_h - fht_zone_extra
        )
    );

function FingerGripZ(i, height) =
    FingerGripZoneBottom(height) + FingerGripZoneHeight(height) * i / (fht_T + 1);


// 摩擦凸点, 用于盒子上下盖子连接
module FrictionBump(length, r, height_index=0.5){
 
    difference() {
        // 半边的圆柱太突出了，少一点
        translate([-r*height_index, 0, 0])
            union(){
                rotate([90, 0, 0]){
                    cylinder(h=length, r=r, center=true);

                    translate([0, 0, length/2]) 
                        sphere(r = r);

                    translate([0, 0, -length/2]) 
                        sphere(r = r);
                }
            }

        cuboid(size=[2*r, length + 2*r, 2*r], anchor=[1, 0, 0]);
    }
}

// 手指位，方便打开盒子
module FingerNotch(upper_length=10, down_length=20, h=5, thick=2){
    rotate([0, 0, 90])
    prismoid(
        size1 = [upper_length, thick],  // 下底：宽20，长10
        size2 = [down_length, thick],  // 上底：宽10，长10（从正面看就是梯形）
        h = h                           // 高度（柱体的长度）
    );

}

// 盒子的主体
module box_down_1_body(wall=2, bottom_t=2, size=[100, 80], height=40, rounding=5, lip_height=2, lip_width_index=0.5){


    if(lip_height > 0){
        // 底板
        cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=BOT);

        // 盒子侧壁
        translate([0, 0, bottom_t])
            rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding, anchor=BOT);

        // 唇边
        translate([0, 0, height]) 
            rect_tube(size = [size.x-wall*2 + wall*2*lip_width_index, size.y-wall*2 + wall * 2*lip_width_index], 
                        wall = wall*lip_width_index, 
                        h = lip_height, 
                        rounding = rounding-wall*(1-lip_width_index),
                        anchor=BOT);

        // 摩擦凸点
        color("red")
            for(i=[1:1:N]){
                y_pos = -size.y/2 + (size.y / (N + 1)) * i;
                translate([size.x/2 - (1-lip_width_index) * wall,  y_pos, height + lip_height/2])
                    FrictionBump(fb_length, fb_r);
            }

        color("blue")
            for(i=[1:1:N]){
                y_pos = -size.y/2 + (size.y / (N + 1)) * i;
                if(!FingerNotchAffectsBump(y_pos))
                    translate([-(size.x/2 - (1-lip_width_index) * wall),  y_pos, height + lip_height/2])
                        rotate([0, 180, 0])
                            FrictionBump(fb_length, fb_r);
            }

        color("yellow")
            for(i=[1:1:M]){
                x_pos = -size.x/2 + (size.x / (M + 1)) * i;
                translate([x_pos,  (size.y/2 - (1-lip_width_index) * wall), height + lip_height/2])
                    rotate([0, 0, 90])
                        FrictionBump(fb_length, fb_r);
            }

        color("green")
            for(i=[1:1:M]){
                x_pos = -size.x/2 + (size.x / (M + 1)) * i;
                translate([x_pos,  -(size.y/2 - (1-lip_width_index) * wall), height + lip_height/2])
                    rotate([0, 0, -90])
                        FrictionBump(fb_length, fb_r);
            }

        // 防滑槽
        for(i=[1:1:fht_T]){
            z_pos = FingerGripZ(i, height);
            translate([-size.x/2,  0, z_pos])
                rotate([0, 180, 0])
                    FrictionBump(fht_length, fht_r);
        }

    }
    else{

        // 凹进去的
        difference(){

            union(){
                // 底板
                cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=BOT);

                // 盒子侧壁
                translate([0, 0, bottom_t])
                    rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding, anchor=BOT);
            }

            // 唇边
            lip_height = abs(lip_height);
            translate([0, 0, height - lip_height + 0.01]) 
                rect_tube(size = [size.x-wall*2 + wall*2*lip_width_index, size.y-wall*2 + wall * 2*lip_width_index], 
                            wall = wall*lip_width_index + 0.01, 
                            h = lip_height, 
                            rounding = rounding-wall*(1-lip_width_index),
                            anchor=BOT);

            // 摩擦凸点
            color("red")
                for(i=[1:1:N]){
                    y_pos = -size.y/2 + (size.y / (N + 1)) * i;
                    translate([size.x/2 -(lip_width_index)*wall,  y_pos, height-lip_height/2])
                        FrictionBump(fb_length, fb_r);
                }

            color("red")
                for(i=[1:1:N]){
                    y_pos = -size.y/2 + (size.y / (N + 1)) * i;
                    translate([-(size.x/2 -(lip_width_index)*wall),  y_pos, height-lip_height/2])
                        rotate([0, 180, 0])
                            FrictionBump(fb_length, fb_r);
                }

            color("yellow")
                for(i=[1:1:M]){
                    x_pos = -size.x/2 + (size.x / (M + 1)) * i;
                    translate([x_pos,  (size.y/2 - (lip_width_index) * wall), height - lip_height/2])
                        rotate([0, 0, 90])
                            FrictionBump(fb_length, fb_r);
                }

            color("green")
                for(i=[1:1:M]){
                    x_pos = -size.x/2 + (size.x / (M + 1)) * i;
                    translate([x_pos,  -(size.y/2 - (lip_width_index) * wall), height - lip_height/2])
                        rotate([0, 0, -90])
                            FrictionBump(fb_length, fb_r);
                }

            // 手指槽
            translate([(size.x/2 - fn_thick/2), 0, height-fn_h])
                FingerNotch(upper_length=fn_upper_length, down_length=fn_down_lenght, h=fn_h, thick=fn_thick);
            }

        difference(){

            union(){
                // 防滑槽
                for(i=[1:1:fht_T]){
                    z_pos = FingerGripZ(i, height);
                    translate([size.x/2,  0, z_pos])
                        FrictionBump(fht_length, fht_r);
                }
            }

            // 手指槽
            translate([(size.x/2), 0, height-fn_h])
                FingerNotch(upper_length=fn_upper_length, down_length=fn_down_lenght, h=fn_h, thick=fn_thick + 50);
            }
    }
}

// 盒子改为可以 attach 的样式
module box_down_1(wall=2, bottom_t=2, size=[100, 80], height=40, rounding=5, lip_height=2, lip_width_index=0.5, body_z_offset=0, anchor=CENTER, spin=0, orient=UP){
    attach_height = height + max(lip_height, 0);

    attachable(anchor, spin, orient, size=[size.x, size.y, attach_height]) {
        translate([0, 0, -attach_height / 2 + body_z_offset])
            box_down_1_body(
                wall=wall,
                bottom_t=bottom_t,
                size=size,
                height=height,
                rounding=rounding,
                lip_height=lip_height,
                lip_width_index=lip_width_index
            );

        children();
    }
}


// 可接铰链的平底盒体模块
module hinged_box_half(size, height, lip_height=lip_height, anchor=CENTER, spin=0, orient=UP, box_hinge_z_offset=0, lip_width_index=0.5) {
    box_down_1(
        wall=wall_thickness,
        bottom_t=bottom_thickness,
        size=size,
        height=height,
        rounding=rounding,
        lip_height=lip_height,
        lip_width_index=lip_width_index,
        body_z_offset=box_hinge_z_offset,
        anchor=anchor,
        spin=spin,
        orient=orient
    ) children();
}

// 主体
translate([-hinge_axis_x, 0, 0]) 
{
    // 下半盒体
    hinged_box_half(
        size=[lower_box_size.x, lower_box_size.y],
        height=lower_box_size.z,
        lip_height=lip_height,
        anchor=TOP,
        box_hinge_z_offset=lip_height,
        lip_width_index=lip_width_index_upper
    ) {

        // 下半盒铰链
        translate([0, 0, hinge_axis_z])
            position(TOP + RIGHT)
                orient(anchor=RIGHT)
                    knuckle_hinge(
                        length = hinge_length,
                        segs = hinge_seg,
                        offset = hinge_offset,
                        arm_height = hinge_arm_base_height,
                        seg_ratio = hinge_seg_ratio,
                        in_place = true,
                        clearance = hinge_clearance,
                        gap = hinge_gap
                    );

        // 上半盒体
        attach(TOP, TOP) {
            // 上半盒整体绕铰链轴旋转
            translate([hinge_axis_x, 0, hinge_axis_z])
                rotate([0, open_angle, 0])
                    translate([-hinge_axis_x, 0, -hinge_axis_z])
                        color("green")
                            hinged_box_half(
                                size=[upper_box_size.x, upper_box_size.y],
                                height=upper_box_size.z,
                                lip_height=-lip_height,
                                anchor=TOP,
                                lip_width_index=lip_width_index_down
                            ) {
                                // 上半盒铰链跟着一起转
                                translate([0, 0, hinge_axis_z + upper_hinge_z_lift])
                                    position(TOP + LEFT)
                                        orient(anchor=LEFT)
                                            knuckle_hinge(
                                                length = hinge_length,
                                                segs = hinge_seg,
                                                offset = hinge_offset,
                                                arm_height = hinge_arm_height,
                                                seg_ratio = hinge_seg_ratio,
                                                inner = true,
                                                in_place = true,
                                                clearance = hinge_clearance,
                                                gap = hinge_gap
                                            );
                                }
        }
    }
}
