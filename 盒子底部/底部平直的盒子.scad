include <BOSL2/std.scad>


module box_down_1(wall=2, bottom_t=2, size=[100, 80], height=40, rounding=5, lip_height=2, lip_width_index=0.5){


    if(lip_height > 0){
        // 底板
        cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=[0,0,1]);

        // 盒子侧壁
        rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding);

        // 唇边
        translate([0, 0, height - bottom_t]) 
            rect_tube(size = [size.x-wall*2 + wall*2*lip_width_index, size.y-wall*2 + wall * 2*lip_width_index], 
                        wall = wall*lip_width_index, 
                        h = lip_height, 
                        rounding = rounding-wall*(1-lip_width_index));
    }
    else{
        // 凹进去的
        difference(){

            union(){
                // 底板
                cuboid([size.x, size.y, bottom_t], rounding = rounding, edges = "Z", anchor=[0,0,1]);

                // 盒子侧壁
                rect_tube(size = size, wall = wall, h = height - bottom_t, rounding = rounding);
            }

            // 唇边
            lip_height = abs(lip_height);
            translate([0, 0, height - bottom_t - lip_height + 0.01]) 
                rect_tube(size = [size.x-wall*2 + wall*2*lip_width_index, size.y-wall*2 + wall * 2*lip_width_index], 
                            wall = wall*lip_width_index + 0.01, 
                            h = lip_height, 
                            rounding = rounding-wall*(1-lip_width_index));
        }
    }
}

// box_down_1(size=[50, 40], height=20, wall=2, rounding=5, lip_height=-1, lip_width_index=0.5);

// translate([60, 0, 0]) 
//     box_down_1(size=[50, 40], height=20, wall=2, rounding=5, lip_height=1, lip_width_index=0.5);

// translate([120, 0, 0]) 
//     box_down_1(size=[50, 40], height=20, wall=2, rounding=5, lip_height=-1, lip_width_index=0.55);







