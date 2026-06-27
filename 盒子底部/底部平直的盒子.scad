include <BOSL2/std.scad>


// 摩擦凸点, 用于盒子上下盖子连接
module FrictionBump(length, r){

    difference() {
        rotate([90, 0, 0]){
            cylinder(h=length, r=r, center=true);

            translate([0, 0, length/2]) 
                sphere(r = r);

            translate([0, 0, -length/2]) 
                sphere(r = r);
        }

        cuboid(size=[2*r, length + 2*r, 2*r], anchor=[1, 0, 0]);
    }
}


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

        // 抹茶凸点

        // 指定 x y 轴的都有几个，然后平均分配就行了
        color("red")
            translate([size.x/2 - (1-lip_width_index) * wall,  0, height + lip_height/2]) 
                FrictionBump(2, 0.5);
            
            translate([size.x/2 - (1-lip_width_index) * wall,  10, height + lip_height/2]) 
                FrictionBump(2, 0.5);

            translate([size.x/2 - (1-lip_width_index) * wall,  -10, height + lip_height/2]) 
                FrictionBump(2, 0.5);
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
        }
    }
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





