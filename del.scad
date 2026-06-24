include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
size=100;
apply_folding_hinges_and_snaps(
    thick=3, foldangle=acos(1/3),
    hinges=[
        for (a=[0,120,240], b=[-size/2,size/4]) each [
            [200, polar_to_xy(b,a), a+90]
        ]
    ],
    snaps=[
        for (a=[0,120,240]) each [
            [rot(a,p=[ size/4, 0        ]), a+90],
            [rot(a,p=[-size/2,-size/2.33]), a-90]
        ]
    ],
    sockets=[
        for (a=[0,120,240]) each [
            [rot(a,p=[ size/4, 0        ]), a+90],
            [rot(a,p=[-size/2, size/2.33]), a+90]
        ]
    ]
) {
    $fn=3;
    difference() {
        cylinder(r=size-1, h=3);
        down(0.01) cylinder(r=size/4.5, h=3.1, spin=180);
        down(0.01) for (a=[0:120:359.9]) zrot(a) right(size/2) cylinder(r=size/4.5, h=3.1);
    }
}