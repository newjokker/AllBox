include <BOSL2/std.scad>


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

module box_down_1_body(wall=2, bottom_t=2, size=[100, 80], height=40, rounding=5, lip_height=2, lip_width_index=0.5){

    // 摩擦凹凸点参数 
    N = 3;
    M = 2;
    fb_length = 1.5;
    fb_r = 0.8;

    fht_length = 15;
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

        // fb_length = fb_length * 1.2;
        // fb_r = fb_r * 1.2;

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


// translate([60, 0, 0]) 
//     box_down_1(size=[50, 40], height=20, wall=2, rounding=5, lip_height=1, lip_width_index=0.5);

// translate([120, 0, 0]) 
//     box_down_1(size=[50, 40], height=20, wall=2, rounding=5, lip_height=-1, lip_width_index=0.55);





