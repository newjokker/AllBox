//=========================
// Parametric Screw Box
//=========================

$fn = 64;

//-------------------------
// 参数
//-------------------------
box_length = 100;
box_width  = 70;
box_height = 40;

wall = 2;
lid_height = 6;

corner_offset = 10;

// M3
screw_hole_d = 3.2;
pillar_d     = 8;

//-------------------------
// 底盒
//-------------------------
module box_bottom()
{
    difference()
    {
        cube([box_length, box_width, box_height]);

        translate([wall, wall, wall])
            cube([
                box_length-2*wall,
                box_width-2*wall,
                box_height
            ]);
    }

    // 四个螺丝柱
    for(x=[corner_offset, box_length-corner_offset])
    for(y=[corner_offset, box_width-corner_offset])
    {
        translate([x,y,0])
        difference()
        {
            cylinder(
                h=box_height-wall,
                d=pillar_d);

            cylinder(
                h=box_height,
                d=screw_hole_d);
        }
    }
}

//-------------------------
// 上盖
//-------------------------
module box_lid()
{
    difference()
    {
        cube([box_length, box_width, lid_height]);

        // 内部凹槽
        translate([wall,wall,0])
            cube([
                box_length-2*wall,
                box_width-2*wall,
                lid_height-wall
            ]);

        // 四个通孔
        for(x=[corner_offset, box_length-corner_offset])
        for(y=[corner_offset, box_width-corner_offset])
        {
            translate([x,y,-1])
                cylinder(
                    h=lid_height+2,
                    d=screw_hole_d);
        }
    }
}

//-------------------------
// 显示
//-------------------------

translate([0,0,0])
    box_bottom();

translate([0,0,box_height+15])
    box_lid();