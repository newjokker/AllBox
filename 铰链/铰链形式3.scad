include <BOSL2/std.scad>
include <BOSL2/hinges.scad>

$fn=64;

// snap_lock(thick=5, foldangle=160);


snap_socket(
    thick = 3,
    snaplen = 3,
    snapdiam = 5,
    layerheight = 0.2,
    foldangle = 90,
    hingegap = 0.5,
    $slop = 0.1,
    anchor=[0,0,0],
    spin = 0
);


snap_lock(
    thick = 3,
    snaplen = 3,
    snapdiam = 5,
    layerheight = 0.2,
    foldangle = 90,
    hingegap = 0.5,
    $slop = 0.1,
    anchor=[0,0,0],
    spin = 0
);


