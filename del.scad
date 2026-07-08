include <BOSL2/std.scad>

// ============ 测试7: 不同纹理深度 ============

size=2.5;

$fn = 200;


difference(){
    cyl(h=20, r=10,
        texture="checkers",
        tex_size=[5,5],
        tex_depth=0.2,       // 浅纹理
        anchor=BOTTOM, rounding=2);

    cyl(h = 55, r =8 ,anchor = CENTER);

    // cuboid([40, 40, 1], anchor=BOTTOM);

}

cylinder(h = h, r = r);
