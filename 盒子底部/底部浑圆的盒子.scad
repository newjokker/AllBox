include <BOSL2/std.scad>

$fn = 64;

thick = 1;

outer_size = [100 + thick*2, 80 + thick*2, 40 + thick*2];
inner_size = [100, 80, 40 + 0.01];

outer_rounding = 5;
inner_rounding = outer_rounding - thick;

round_edges = [
    BOTTOM,
    FRONT+LEFT,
    FRONT+RIGHT,
    BACK+LEFT,
    BACK+RIGHT
];

difference() {
    cuboid(
        outer_size,
        rounding = outer_rounding,
        edges = round_edges
    );

    translate([0, 0, thick])
        cuboid(
            inner_size,
            rounding = inner_rounding,
            edges = round_edges
        );
}