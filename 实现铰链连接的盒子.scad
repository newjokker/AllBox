include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn = 128;


// ---------------- 参数 ----------------

// 上半盒子的尺寸
upper_box_size = [60, 120, 10];

// 下半盒体尺寸
lower_box_size = [60, 120, 25];

hinge_offset = 2.5;

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
lip_width_index_down    = 0.55;

// 铰链的长度
hinge_length = 90;          // 

// 铰链节的个数
hinge_seg = 9;              // [3:2:15]

// 上下铰链长度的比例
hinge_seg_ratio = 1;        // [0.3:0.1:2]

// 两半铰链之间的间隙
hinge_clearance = 0.35;  

// 铰链节之间的间隙，当铰链大小不变化的时候，一般固定即可 
hinge_gap = 0.25;         
hinge_arm_base_height = 1;
hinge_arm_extra_height = abs(lower_box_size.z - upper_box_size.z) / 2 + 3.5;

// 绿色上盖铰链的单独高度微调。正数表示在 open_angle=180 平放预览时，把绿色铰链向上提。
upper_hinge_z_lift = 15;

// 铰链轴心距离盒子中心的 X 距离
hinge_axis_x = lower_box_size.x / 2 + hinge_offset;

// 上下高度不一致时，闭合基准仍在 lip 处；
// 铰链轴放在高度差的中点，180 度展开时两半盒子的外表面会共面。
hinge_axis_z = (upper_box_size.z - lower_box_size.z) / 2;

// 高度不一致时，铰链的安装臂需要多伸出一段去够到共同轴线。
// 如果预览里连接臂还不够长，可以只调大 hinge_arm_extra_height。
hinge_arm_height = hinge_arm_base_height + hinge_arm_extra_height;


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

    // 摩擦凹凸点参数 
    N = 3;
    M = 2;
    fb_length = 1.5;
    fb_r = 0.8;

    fht_length = 20;
    fht_r = 0.4;
    fht_T = 4;

    // 手指槽参数
    fn_upper_length = 10;
    fn_down_lenght = 20;
    fn_h = 5;
    fn_thick = 1.5;


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
            z_pos = (height / (fht_T + 1)) * i;
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
                    z_pos = (height / (fht_T + 1)) * i;
                    translate([size.x/2,  0, z_pos])
                        FrictionBump(fht_length, fht_r);
                }
            }

            // 手指槽
            translate([(size.x/2), 0, height-fn_h])
                FingerNotch(upper_length=fn_upper_length, down_length=fn_down_lenght, h=fn_h, thick=fn_thick + 50);

            }


    }
        // color("red")
        //     // 手指槽
        //     translate([-(size.x/2 - fn_thick/2), 0, height-5])
        //         FingerNotch(upper_length=fn_upper_length, down_length=fn_down_lenght, h=fn_h, thick=fn_thick);

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
