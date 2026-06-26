include <BOSL2/std.scad>

$fn = 64;

thick = 1;

length = 50;
width = 40;
height = 20;

outer_size = [length , width, height];
inner_size = [length- thick*2, width - thick*2, height- thick*2 + 0.01];

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