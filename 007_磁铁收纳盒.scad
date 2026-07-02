include <BOSL2/std.scad>

$fn = 148;


// module A(h, r){

//     difference(){

//         cuboid([6,4.6,h], anchor=[0,0,-1]);
//         // cylinder(r=4, h=h, center=false);
        
//         translate([0, 0.5, 3])
//             cylinder(r=2.15, h=h, center=false);

//         translate([0, 0.5, 1])
//             cylinder(r=1.15, h=h, center=false);
//     }
// }

// A(20, 2);

$fn = 80;


// 保留 X 正方向半球：平面在 x=0，凸起朝 +X
module half_sphere_x_pos(r) {
    intersection() {
        sphere(r);
        translate([0, -r, -r])
            cube([r, 2*r, 2*r]);
    }
}


// 保留 X 负方向半球：平面在 x=0，凸起朝 -X
module half_sphere_x_neg(r) {
    intersection() {
        sphere(r);
        translate([-r, -r, -r])
            cube([r, 2*r, 2*r]);
    }
}


// U 型结构 + 两个内侧半球
module u_part(
    width = 120,
    height = 80,
    thick = 8,
    depth = 20,
    ball_r = 10,
    ball_y = 40
) {
    union() {
        // 左边壁
        cube([thick, height, depth]);

        // 右边壁
        translate([width - thick, 0, 0])
            cube([thick, height, depth]);

        // 底边壁
        cube([width, thick, depth]);

        // 左内壁半球，贴在 x = thick 表面，朝内凸起
        translate([thick, ball_y, depth/2])
            half_sphere_x_pos(ball_r);

        // 右内壁半球，贴在 x = width - thick 表面，朝内凸起
        translate([width - thick, ball_y, depth/2])
            half_sphere_x_neg(ball_r);
    }
}


// 示例
u_part(
    width = 120,
    height = 80,
    thick = 8,
    depth = 20,
    ball_r = 10,
    ball_y = 40
);