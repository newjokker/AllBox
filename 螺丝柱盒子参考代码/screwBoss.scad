screwBossTest();
module screwBossTest(){
    $fn=50;
    geom=[
        // See e.g. https://www.pipingmaterial.ae/iso-4762/
        // "ISO4762 Socket Head Cap Screw Specifications"
        
        // Screw "class":
        // "my1" implies additional, application-dependent input over the ISO standard e.g. screw length that needs to be reviewed.

        // threaded hole. Mx minus some margin. E.g. -10% (that is, 2.7mm for M3), tune for printer.
        ["ISO4762_my1.threadDiam", 2.7],   // screw hole diameter (threaded part)
        // non-threaded hole. Mx plus some margin. E.g. +10% (that is, 3.3mm for M3), tune for printer.
        ["ISO4762_my1.shankDiam", 3.4],   // screw hole diameter (non-threaded part)
        ["ISO4762_my1.shankLength", 2],   // bolt length between head and threaded end. Depends on actual screw
        ["ISO4762_my1.headHeight", 3],   // screw head height
        ["ISO4762_my1.headDiam", 5.5],   // screw head diameter
        ["ISO4762_my1.headWallThickness", 1.1], // thickness of screw recess (load bearing!)
        ["ISO4762_my1.standoffWallThicknessLo", 0.8], // thickness of standoff where the screw enters (minimum torque)
        ["ISO4762_my1.standoffWallThicknessHi", 1.2], // thickness of standoff at boss end (maximum torque)
        ["ISO4762_my1.bossLength", 22],   // total length of screw boss, equals the length of the screw as measured in calipers
        ["ISO4762_my1.bossPadDiam", 10],
    
        ["infinity", 345],      // "large number" use reasonable value when working with preview
        ["eps", 0.01]           // "small number" for overlapping solids
    ];

        prefix = "ISO4762_my1";
        delta = 30;
        // top, additive only
        translate([0*delta, 0, 0]) screwBossTopAdd(geom, prefix);

        // bottom, additive only
        translate([1*delta, 0, 0]) screwBossBottomAdd(geom, prefix);

        // top/bottom, additive only
        translate([2*delta, 0, 0]) union(){screwBossTopAdd(geom, prefix);screwBossBottomAdd(geom, prefix);};

        // subtractive part
        translate([3*delta, 0, 0]) screwBossSub(geom, prefix);

        // top, add/sub
        translate([4*delta, 0, 0]) difference(){union(){screwBossTopAdd(geom, prefix);}; screwBossSub(geom, prefix);};

        // bottom, add/sub
        translate([5*delta, 0, 0]) difference(){union(){screwBossBottomAdd(geom, prefix);}; screwBossSub(geom, prefix);};

        // combined, add/sub
        translate([6*delta, 0, 0]) difference(){union(){screwBossTopAdd(geom, prefix); screwBossBottomAdd(geom, prefix);}; screwBossSub(geom, prefix);};       
} // module test

// ADDITIVE head part of screw boss in positive z direction starting from head (centered on the hex socket's outer end)
module screwBossTopAdd(geom, prefix){    
    headHeight = get_param(geom, str(prefix, ".headHeight")); 
    shankLength = get_param(geom, str(prefix, ".shankLength")); 
    headDiam = get_param(geom, str(prefix, ".headDiam")); 
    headWallThickness = get_param(geom, str(prefix, ".headWallThickness")); 
    shankDiam = get_param(geom, str(prefix, ".shankDiam")); 
    threadDiam = get_param(geom, str(prefix, ".threadDiam")); 
    bossLength = get_param(geom, str(prefix, ".bossLength")); 
    
    inf=get_param(geom, "infinity"); //  large number. Usually common to the design - not prefixed
    eps=get_param(geom, "eps"); //  small number. Usually common to the design - not prefixed    
    
    union(){
        // screw head recess
        translate([0, 0, 0])
            cylinder(h = headHeight+headWallThickness, r = 1/2*(headWallThickness+headDiam+headWallThickness));
    }    
}

// ADDITIVE bottom part of screw boss in positive z direction starting from head (centered on the hex socket's outer end)
module screwBossBottomAdd(geom, prefix){    
    headHeight = get_param(geom, str(prefix, ".headHeight")); 
    headWallThickness = get_param(geom, str(prefix, ".headWallThickness")); 
    shankLength = get_param(geom, str(prefix, ".shankLength")); 
    headDiam = get_param(geom, str(prefix, ".headDiam")); 
    shankDiam = get_param(geom, str(prefix, ".shankDiam")); 
    threadDiam = get_param(geom, str(prefix, ".threadDiam")); 
    bossLength = get_param(geom, str(prefix, ".bossLength")); 
    standoffWallThicknessHi = get_param(geom, str(prefix, ".standoffWallThicknessHi")); 
    standoffWallThicknessLo = get_param(geom, str(prefix, ".standoffWallThicknessLo")); 
    bossPadRadius = 0.5*get_param(geom, str(prefix, ".bossPadDiam")); 
    inf=get_param(geom, "infinity"); //  large number. Usually common to the design - not prefixed
    eps=get_param(geom, "eps"); //  small number. Usually common to the design - not prefixed    

    cylRadiusLo = 1/2*(standoffWallThicknessLo+threadDiam+standoffWallThicknessLo);
    cylRadiusHi = 1/2*(standoffWallThicknessHi+threadDiam+standoffWallThicknessHi);
    bossPadRadiusDelta = max(0, bossPadRadius - cylRadiusHi);
    bossPadHeight = bossPadRadiusDelta; // 90-degree circle segment 
    union(){
        // standoff around non-threaded screw section(shank)
        translate([0, 0, headHeight+headWallThickness]) // overlaps one wall thickness into screw head recess
            cylinder(
                h = shankLength, 
                r1 = cylRadiusLo,
                r2 = cylRadiusLo
        );
        
        // threaded section
        translate([0, 0, headHeight+headWallThickness+shankLength])
            cylinder(
                h = bossLength-headHeight-headWallThickness-shankLength-bossPadHeight, 
                r1 = cylRadiusLo,
                r2 = cylRadiusHi
        );

        // screw boss pad
        translate([0, 0, bossLength])
            rotate([180, 0, 0])
                standoffFoot(cylRadiusHi, bossPadHeight);
    } // union
}

// SUBTRACTIVE part of screw boss (both upper / lower half for simplicity)
module screwBossSub(geom, prefix, x, y){    
    headHeight = get_param(geom, str(prefix, ".headHeight")); 
    shankLength = get_param(geom, str(prefix, ".shankLength")); 
    headDiam = get_param(geom, str(prefix, ".headDiam")); 
    shankDiam = get_param(geom, str(prefix, ".shankDiam")); 
    threadDiam = get_param(geom, str(prefix, ".threadDiam")); 
    bossLength = get_param(geom, str(prefix, ".bossLength")); 
    standoffWallThicknessHi = get_param(geom, str(prefix, ".standoffWallThicknessHi")); 
    inf=get_param(geom, "infinity"); //  large number. Usually common to the design - not prefixed
    eps=get_param(geom, "eps"); //  small number. Usually common to the design - not prefixed    

    // spherical end (the hole extends slightly into the material to distribute stress)
    bottomSphereRadius = threadDiam/2;
    union(){
        // screw head recess
        translate([0, 0, -eps])
            cylinder(
                h = headHeight+2*eps, 
                r = 1/2*headDiam);
        translate([0, 0, headHeight-eps])
            cylinder(
                h = shankLength+2*eps, 
                r = 1/2*shankDiam);
        translate([0, 0, headHeight+shankLength-eps])
            cylinder(
                h = bossLength-headHeight-shankLength+eps-bottomSphereRadius-standoffWallThicknessHi, 
                r = 1/2*threadDiam);
        translate([0, 0, headHeight+shankLength-eps+bossLength-headHeight-shankLength-bottomSphereRadius-standoffWallThicknessHi])
            sphere(
                r = bottomSphereRadius);
    } // union
}

// helper function: Cylinder that curves 90 degrees onto a surface
module standoffFoot(rCylinder, height){
    difference(){
        cylinder(h=height, r=rCylinder+height);
    translate([0, 0, height])
        rotate_extrude(angle=360)
            translate([rCylinder+height, 0, 0])
                circle(r=height);
    }; // difference
}

function get_param(params, key) =
    let (tmp = [for (p = params) if (p[0]==key) p[1]])
        len(tmp) == 1 ? tmp[0] : assert(0, str("parameter '", key, "' not found"));
