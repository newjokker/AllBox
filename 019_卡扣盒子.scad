include <BOSL2/std.scad>

$fn = 64;

/* [Size] */
// Box width
width = 160; // [30:1:256]
// Box depth
depth = 80; // [30:1:256]
// Lid height
height_top = 10; // [10:1:256]
// Bottom part height
height_bottom = 60; // [10:1:256]
// Wall thickness
wall = 2;
// Box walls radius
radius = 4;

/* [Hinges] */
// Distance from box side to the hinges
hinge_from_wall = 10; // [7:1:120]
// Width of the hinges
hinge_width = 10; // [4:1:50]

/* [Latch] */
// Latch size
latch_width = 5; // [1:1:50]

/* [Separators] */
// Separators configuration. Format: (v/h)(x),(y),(length / f),(height / f)
separators_config_string = "v80,0,f,f h80,40,f,f";

/* [Other] */
// Show as two separate pieces
exploded = true;
show = "all"; // [all:top:bottom]

// Simple parser
function parse_string(input_str) =
let(
    // Split the input string into blocks (separated by spaces)
    blocks = [for (s = str_split(input_str, " ")) s],

    // Process each block into its own array
    result = [for (block = blocks)
        let(
            // First character is the type (v or h)
            type = substr(block, 0, 1),
            // Rest is numbers separated by commas
            numbers_str = substr(block, 1),
            // Split numbers by comma and convert to numbers
            numbers = [for (n = str_split(numbers_str, ",")) is_letter(n) ? n : parse_float(n)]
        )
        concat([type], numbers)
        ]
)
result;

separators_config = separators_config_string ? parse_string(separators_config_string) : [];

// Actual code
module box() {
    hinge_distance = width / 2 - hinge_from_wall - hinge_width / 2;

    module rounded_bottom_box(width, depth, height, radius) {
        difference() {
            translate([-width / 2 + radius, -depth / 2 + radius, radius])
                minkowski() {
                    cube([width - radius * 2, depth - radius * 2, height - radius]);
                    sphere(r = radius);
                }

            translate([-width / 2, -depth / 2, height])
                cube([width, depth, radius]);
        }
    }

    module box_with_cutout(width, depth, height, wall, radius) {
        difference() {
            rounded_bottom_box(width, depth, height, radius);

            translate([0, 0, wall])
                // +1 is for fixing geometry in openscad
                rounded_bottom_box(width - wall * 2, depth - wall * 2, height - wall + 1, radius - wall);
        }
    }

    module top_part() {
        module latch_2() {
            latch_thickness = 3;
            latch_height = 5.68;
            some_radius = 2;
            whole_latch_width = latch_width + 10;
            offset_from_top = 0;

            translate([-whole_latch_width / 2, depth / 2 + latch_thickness / 2, height_top + offset_from_top +
                    latch_height / 2])
                rotate([90, 0, 90])
                    difference() {
                        linear_extrude(height = whole_latch_width) {
                            union() {
                                square([latch_thickness, latch_height], center = true);

                                translate([0, latch_height / 2, 0])
                                    circle(d = latch_thickness);

                                intersection() {
                                    translate([-some_radius + latch_thickness / 2, -latch_height / 2, 0])
                                        circle(r = some_radius);

                                    translate([0, -latch_height / 2, 0])
                                        square([latch_thickness, latch_height], center = true);

                                }

                                translate([-latch_thickness / 2, -6.6, 0])
                                    difference() {
                                        translate([0, 0, 0])
                                            square([some_radius, some_radius]);

                                        translate([some_radius, 0, 0])
                                            circle(r = some_radius);
                                    }
                            }
                        }

                        small_width = 2.1;
                        big_width = 3.7;
                        hole_depth = 1.5;
                        how_width = latch_width + 0.4;
                        distance_from_top = 0.5;
                        points = [
                                [0, 0],
                                [hole_depth, (big_width - small_width) / 2],
                                [hole_depth, (big_width - small_width) / 2 + small_width],
                                [0, big_width + 1]
                            ];

                        translate([-hole_depth - 0.01, -big_width / 2 + distance_from_top, whole_latch_width / 2])
                            linear_extrude(height = how_width, center = true)
                                polygon(points = points);
                    }
        }

        module hinge_2() {
            a = 8.817;
            b = 3.714;
            c = 5.6;
            e = 5.214;
            hinge_depth = hinge_width - 0.3; // depth
            offset_from_top = -1.1; // from top

            points = [
                    [0, 0],
                    [2.5, 0],
                    [0, 0.9]
                ];

            module hinge_2_1() {
                translate([-hinge_depth / 2, -depth / 2 - c / 2, a / 2 + height_top - e])
                    rotate([90, -180, 90])
                        difference() {
                            linear_extrude(height = hinge_depth)
                                union() {
                                    translate([0, -(a - b) / 2, 0])
                                        square([c, b], center = true);

                                    translate([0, -a / 2, 0])
                                        circle(d = c);

                                    intersection() {
                                        translate([-c / 2, -(c * 2 - a) / 2, 0])
                                            circle(r = c);

                                        square([c, a], center = true);
                                    }
                                }

                            translate([0, -a / 2, 0])
                                rotate_extrude()
                                    polygon(points = points);

                            translate([0.15, -a / 2, hinge_depth + 0.01])
                                rotate([180, 0, 0])
                                    rotate_extrude()
                                        polygon(points = points);

                        }
            }

            translate([hinge_distance, 0, offset_from_top])
                hinge_2_1();

            translate([-hinge_distance, 0, offset_from_top])
                hinge_2_1();

        }

        box_with_cutout(width, depth, height_top, wall, radius);
        latch_2();
        hinge_2();
    }

    module bottom_part() {
        module separators() {
            intersection() {
                rounded_bottom_box(width, depth, height_bottom, radius);

                union() {
                    for (separator = separators_config) {
                        is_h = separator[0] == "h";
                        if (separator[0] == "h") {
                            x = separator[1];
                            y = separator[2];
                            s_depth = is_num(separator[3]) ? separator[3] : width;
                            s_height = is_num(separator[4]) ? separator[4] : height_bottom;
                            translate([+x - width / 2, depth / 2 - wall / 2 - y, 0])
                                cube([s_depth, wall, s_height]);
                        } else {
                            x = separator[1];
                            y = separator[2];
                            s_depth = is_num(separator[3]) ? separator[3] : depth;
                            s_height = is_num(separator[4]) ? separator[4] : height_bottom;
                            translate([-width / 2 + x, -s_depth / 2 - y, 0])
                                cube([wall, s_depth, s_height]);
                        }
                    }
                }
            }
        }
        module latch_1() {
            h1 = 2; // small height
            h2 = 3.5; // big height
            w = 1.5; // width
            ft = 1.3; // distance from top
            points = [
                    [0, 0],
                    [w, (h2 - h1) / 2],
                    [w, (h2 - h1) / 2 + h1],
                    [0, h2]
                ];

            translate([-latch_width / 2, -depth / 2, height_bottom - ft])
                rotate([90, 180, 90])
                    linear_extrude(height = latch_width)
                        polygon(points = points);
        }

        module hinge_1() {
            w = hinge_width + 2.5; // width
            dist = 2.8; // distance from the wall
            d = 5; // diameter of circle
            t = 2.5; // thickness
            ft = 2.5; // from top
            h = 1.0; // height of cone
            r = 2.4; // radius of cone

            module hinge_1_1(dist, d, t, ft) {
                translate([-t / 2, depth / 2 + dist, height_bottom - ft])
                    rotate([90, 180, 90])
                        linear_extrude(height = t)
                            difference() {
                                union() {
                                    circle(d = d);
                                    translate([0, -d / 2, 0])
                                        square([dist, d + d / 2]);
                                }

                                translate([0, (dist + d / 2), 0])
                                    circle(d = dist * 2);
                            }
            }

            module hinge_1_2(h) {
                points = [
                        [0, 0],
                        [r, 0],
                        [0, h]
                    ];

                rotate([0, 90, 0])
                    rotate_extrude()
                        polygon(points = points);
            }


            translate([hinge_distance, 0, 0])
                union() {
                    translate([w / 2, 0, 0])
                        hinge_1_1(dist = dist, d = d, t = t, ft = ft);
                    translate([-w / 2, 0, 0])
                        hinge_1_1(dist = dist, d = d, t = t, ft = ft);

                    translate([-w / 2 + t / 2, depth / 2 + dist, height_bottom - ft])
                        hinge_1_2(h = h);

                    translate([w / 2 - t / 2, depth / 2 + dist, height_bottom - ft])
                        rotate([0, 180, 0])
                            hinge_1_2(h = h);
                }

            translate([-hinge_distance, 0, 0])
                union() {
                    translate([w / 2, 0, 0])
                        hinge_1_1(dist = dist, d = d, t = t, ft = ft);
                    translate([-w / 2, 0, 0])
                        hinge_1_1(dist = dist, d = d, t = t, ft = ft);

                    translate([-w / 2 + t / 2, depth / 2 + dist, height_bottom - ft])
                        hinge_1_2(h = h);

                    translate([w / 2 - t / 2, depth / 2 + dist, height_bottom - ft])
                        rotate([0, 180, 0])
                            hinge_1_2(h = h);
                }
        }

        latch_1();
        hinge_1();

        box_with_cutout(width, depth, height_bottom, wall, radius);
        separators();
    }

    if (exploded) {
        if (show != "bottom") {
            color([1, 1, 0])
                translate([0, depth + 15, 0])
                    top_part();
        }


        if (show != "top") {
            color([0, 1, 1])
                bottom_part();
        }

    } else {
        if (show != "bottom") {
            color([1, 1, 0, 0.5])
                translate([0, 0, height_bottom + height_top])
                    rotate([180, 0, 0])
                        top_part();
        }

        if (show != "top") {
            color([0, 1, 1, 0.2])
                bottom_part();
        }
    }
}

box();
