use <screwBoss.scad>
use <boxRib.scad>
function get_param(params, key) =
    let (tmp = [for (p = params) if (p[0]==key) p[1]])
        len(tmp) == 1 ? tmp[0] : assert(0, str("parameter '", key, "' not found"));

module bodyBoxPrimitive(innerWidth, innerLength, innerHeight, outerRadius){
	minkowski(){
		cube([innerWidth-2*outerRadius, innerLength-2*outerRadius, innerHeight-2*outerRadius], center=true); 
		sphere(r=outerRadius);
	}
};

// internal parameters depend on user input, calculated here
function boxGeom_dependentFields(geom) = 
    let(
        // === recall independent parameters ===
        screwBossPrefix = get_param(geom, "screwBossPrefix"), 
        innerHeight=get_param(geom, "innerHeight"),
        wallThickness=get_param(geom, "wallThickness"))
        // === set dependents ===
            concat(geom, 
                // the "screwBoss" length includes the thickness of the wall on the screw hole side
                // but not the wall where the screw boss attaches on the inside.
                [[str(screwBossPrefix, ".bossLength"), 
                innerHeight + wallThickness]]);

module cutoutsXYR(cutoutsXYR, cutoutZ, cutoutThickness){
    for (cutoutXYR = cutoutsXYR){
        assert(len(cutoutXYR) == 3, "expecting three-field element for cutoutsTopXYR");
        let(cutoutX = cutoutXYR[0], cutoutY = cutoutXYR[1], cutoutR = cutoutXYR[2]){
            translate([cutoutX, cutoutY, cutoutZ])
                        linear_extrude(height = cutoutThickness)
                            circle(r=cutoutR);
        }; // let
    }; // for cutout    
} // module

module boxTop(geom_){
    geom = boxGeom_dependentFields(geom_);
    screwXY=get_param(geom, "screwXY"); 
    innerHeight=get_param(geom, "innerHeight");
    wallThickness=get_param(geom, "wallThickness"); 
    screwBossPrefix = get_param(geom, "screwBossPrefix");
    screwBossZ = -innerHeight/2 - wallThickness;
    eps=get_param(geom, "eps"); 

    cutoutsXYR = get_param(geom, "cutoutsTopXYR");
    ribsInnerThickness=get_param(geom, "ribsInnerThickness"); 
    cutoutEps = 0.1;
    cutoutZ = -innerHeight/2-wallThickness-cutoutEps;
    cutoutThickness = wallThickness+ribsInnerThickness+2*cutoutEps;

    difference(){
        // === ADD ===
        union(){
            intersection(){
                union(){
                    // shell
                    caseTop(geom);
                    // screw bosses 
                    for (screw = screwXY){
                        let(screwX = screw[0], screwY = screw[1]){
                            translate([screwX, screwY, -screwBossZ])
                                rotate([0, 180, 0]) // note: screw "top" goes into "bottom" case shell
                                    screwBossBottomAdd(geom, screwBossPrefix);
                        } // let
                    }; // for screw
                }; // union (+)
                // === clip screw butts to outer shell ===
                caseOuterShell(geom);
            }; // intersection 
            difference(){
                // === intersection: ADD ===
                caseRibs(geom);
                // === intersection: SUB ===
                caseKeepBottom(geom);
            } // difference
        }; // union
        // === SUBTRACT ===
        union(){
            // cut screw bosses that extend into top-/bottom connection area
            caseBottom(geom);
            // cut screw holes
            for (screw = screwXY){
                let(screwX = screw[0], screwY = screw[1]){
                    translate([screwX, screwY, -screwBossZ])
                        rotate([0, 180, 0])
                            screwBossSub(geom, screwBossPrefix);            
                }; // let
            }; // for screw
            cutoutsXYR(cutoutsXYR, cutoutZ, cutoutThickness);
        } // union (-)    
    }; // difference       
} // module

module boxBottom(geom_){
    geom = boxGeom_dependentFields(geom_);
    screwXY=get_param(geom, "screwXY"); 
    innerHeight=get_param(geom, "innerHeight");
    wallThickness=get_param(geom, "wallThickness"); 
    screwBossPrefix = get_param(geom, "screwBossPrefix");
    screwBossZ = -innerHeight/2 - wallThickness;

    cutoutsXYR = get_param(geom, "cutoutsBottomXYR");
    cutoutEps = 0.1;
    cutoutZ = innerHeight/2-cutoutEps;
    cutoutThickness = wallThickness+2*cutoutEps;

    difference(){
        // === ADD ===
        union(){
            intersection(){
                union(){
                    // shell
                    caseBottom(geom);
                    // screw bosses 
                    for (screw = screwXY){
                        let(screwX = screw[0], screwY = screw[1]){
                            translate([screwX, screwY, -screwBossZ])
                                rotate([0, 180, 0]) // note: screw "top" goes into "bottom" case shell
                                    screwBossTopAdd(geom, screwBossPrefix);
                        } // let
                    }; // for screw
                }; // union (+)
                // === clip screw head recesses to outer shell ===
                caseOuterShell(geom);
            }; // intersection
            intersection(){
                // === intersection: ADD ===
                caseRibs(geom);
                // === intersection: SUB ===
                caseKeepBottom(geom);
            } // difference
        }; // union
        // === SUBTRACT ===
        union(){
            // cut screw bosses that extend into top-/bottom connection area
            caseTop(geom);
            // cut screw holes
            for (screw = screwXY){
                let(screwX = screw[0], screwY = screw[1]){
                    translate([screwX, screwY, -screwBossZ])
                        rotate([0, 180, 0])
                            screwBossSub(geom, screwBossPrefix);            
                }; // let
            } // for screw
            cutoutsXYR(cutoutsXYR, cutoutZ, cutoutThickness);
        } // union (-)    
    }; // difference       
} // module

module caseBottom(geom){
    intersection(){
        caseTopBottom(geom);
        caseKeepBottom(geom);    
    }
}

module caseTop(geom){
    difference(){
        caseTopBottom(geom);
        caseKeepBottom(geom);    
    }
}

module caseKeepBottom(geom){
    myInfinity=get_param(geom, "infinity"); 
    eps=get_param(geom, "eps"); 
	outerRadius=get_param(geom, "outerRadius"); 
    rimThickness = 0.5*get_param(geom, "wallThickness"); 
    rimHeight = 1.1*get_param(geom, "wallThickness"); 
    innerWidth=get_param(geom, "innerWidth"); 
    innerLength=get_param(geom, "innerLength"); 

    union(){
        // shell to keep is positive z
        translate([0,0,myInfinity/2])
            cube([myInfinity+eps, myInfinity+eps, myInfinity+eps], center=true);
        // add a half-thickness rim to align the shells
        translate([0, 0, -rimHeight])
            linear_extrude(height=rimHeight+eps)
                minkowski(){
                    circle(r=outerRadius); 
                    square([
                        innerWidth-2*outerRadius+2*rimThickness, 
                        innerLength-2*outerRadius+2*rimThickness], 
                        center=true);                
                } // minkowski
    } // union
} // module

module caseOuterShell(geom){
    innerWidth=get_param(geom, "innerWidth"); 
    innerLength=get_param(geom, "innerLength"); 
    innerHeight=get_param(geom, "innerHeight");
    outerRadius=get_param(geom, "outerRadius"); 
    wallThickness=get_param(geom, "wallThickness"); 

    bodyBoxPrimitive(innerWidth+2*wallThickness, innerLength+2*wallThickness, innerHeight+2*wallThickness, outerRadius);
} // module

module caseInnerShell(geom){
    innerWidth=get_param(geom, "innerWidth"); 
    innerLength=get_param(geom, "innerLength"); 
    innerHeight=get_param(geom, "innerHeight");
    outerRadius=get_param(geom, "outerRadius"); 

    bodyBoxPrimitive(innerWidth, innerLength, innerHeight, outerRadius);
}

module caseTopBottom(geom){
    difference(){
        caseOuterShell(geom);
        caseInnerShell(geom);
    }
}

module caseRibs(geom){
    wallThickness=get_param(geom, "wallThickness"); 
    innerWidth=get_param(geom, "innerWidth"); 
    innerLength=get_param(geom, "innerLength"); 
    innerHeight=get_param(geom, "innerHeight");
    outerRadius=get_param(geom, "outerRadius"); 
    ribsInnerThickness=get_param(geom, "ribsInnerThickness"); 
    ribsInnerX=get_param(geom, "ribsInnerX"); 
    ribsInnerY=get_param(geom, "ribsInnerY"); 
    for (ribY = ribsInnerY){
        translate([0, ribY, 0])
            rotate([90, 0, 0])
                boxRib(innerWidth-2*ribsInnerThickness, innerHeight-2*ribsInnerThickness, ribsInnerThickness, outerRadius);
    }; // for
    for (ribX = ribsInnerX){
        translate([ribX, 0, 0])
            rotate([90, 0, 90])
                boxRib(innerLength-2*ribsInnerThickness, innerHeight-2*ribsInnerThickness, ribsInnerThickness, outerRadius);
    }; // for
}