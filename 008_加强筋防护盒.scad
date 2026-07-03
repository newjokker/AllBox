/* LICENSE 

This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) license
https://creativecommons.org/licenses/by-sa/4.0/legalcode  

Author: Christof Dornbierer, christof.dornbierer@gmail.com
Version 2.0
Date: 02/12/2026
License: CC-BY-NC-SA 4.0

Tips: https://paypal.me/dornies    :-) 
*/


/* USAGE
ruggedBox(....);

Parameters
    length              --> outside length of box without ribs
    width               --> outside width of box without ribs
    height              --> outside height of box 
    fillet              --> fillet radius (default:4)
    shell               --> shell thickness (default: 3)
    rib                 --> rib thickness (default: 10)
    top=false           --> render top or bottom part of box
    clearance=0.3       --> clearance for joints (default: 0.3)
    fillHeight=0        --> fill box up to that height e.g. to allow cut outs (default: 0)

*/



//true if inside dimensions of box are given, false if outside dimensions are given
inside=true;

//length (inside or outside depending on "inside parameter")
length=50;

//width (inside or outside depending on "inside parameter")
width=50;

//height (inside or outside depending on "inside parameter")
height=30;

//shell thickness
shellThickness=3; // [3:9]

//rib thickness
ribThickness=10; // [6:20]

//fillet radius
filletRadius=4; // [4:20]

//axis diameter (e.g. a piece of 1.75mm filament
axisDiameter=1.9;

//bottom half vs. upper half cut in percent
bottomHalfRatio=70; //[30:70]

//resolution
$fn=64;

//show example
showExample=true;

//show example combined
showExampleCombined=false;


//calculated dimensions of box
outSideLength=inside?length+2*shellThickness:length-2*shellThickness;
outSideWidth=inside?width+2*shellThickness:width-2*shellThickness;
outSideHeight=inside?height+2*shellThickness:height;

//calculated heights top split box
heiBottom=bottomHalfRatio/100*outSideHeight;
heiTop=outSideHeight-heiBottom;




//EXAMPLE
if(showExample){
    
         //bottom
        color([0.5,0.5,1])
        translate([0,-(outSideWidth+4*shellThickness)/2,0])
        ruggedBox(length=outSideLength, width=outSideWidth, height=heiBottom, fillet=filletRadius, shell=shellThickness, rib=ribThickness, top=false, fillHeight=0, axis=axisDiameter);
    
        //top
        color([1,1,1])
        translate([0,(outSideWidth+4*shellThickness)/2,0])
        ruggedBox(length=outSideLength, width=outSideWidth, height=heiTop, fillet=filletRadius, shell=shellThickness, rib=ribThickness, top=true, axis=axisDiameter); 
    
}

if(showExampleCombined){
        //bottom
        color([0.5,0.5,1])
        translate([0,-1.5*outSideWidth-6*shellThickness,0])
        ruggedBox(length=outSideLength, width=outSideWidth, height=heiBottom, fillet=filletRadius, shell=shellThickness, top=false, fillHeight=0,axis=axisDiameter);
    
        //top
        color([1,1,1])
        translate([-outSideLength/2-heiTop-shellThickness,-1.5*outSideWidth-6*shellThickness,outSideHeight+outSideLength/2-heiTop+shellThickness])
        rotate([0,270,180])
        ruggedBox(length=outSideLength, width=outSideWidth, height=heiTop, fillet=filletRadius, shell=shellThickness, top=true, axis=axisDiameter); 
}



//main module
module ruggedBox(length, width, height, fillet=4, shell=3, rib=10, top=false, clearance=0.3, fillHeight=0, axis=1.9){
    union(){
        difference(){
            union(){
                translate([-length/2+fillet+shell, -width/2+fillet+shell,0])
                union(){
                    //lower part
                    minkowski()
                    {
                      cube([length-2*fillet-2*shell,width-2*fillet-2*shell,height-shell]);
                      cylinder(r1=fillet, r2=fillet+shell,h=shell);
                    }

                    //upper part
                    translate([0,0,height-2*shell])
                    minkowski()
                    {
                      cube([length-2*fillet-2*shell,width-2*fillet-2*shell,shell]);
                      cylinder(r1=fillet+shell, r2=fillet+2*shell,h=shell);
                    }
                   
                }
                //ribs
                oneRibY(length, width, height, fillet, shell, rib);
                mirror([1,0,0])oneRibY(length, width, height, fillet, shell, rib);
                oneRibX(length, width, height, fillet, shell, rib);
                mirror([0,1,0])oneRibX(length, width, height, fillet, shell, rib);
                
                //top rabbet
                if(top==true)topRabbet(length, width, height, fillet, shell);
            }

            //inside cut out
            translate([-length/2+fillet+shell, -width/2+fillet+shell,shell+fillHeight])
            minkowski()
            {
              cube([length-2*fillet-2*shell,width-2*fillet-2*shell,height-2*shell+0.1]);
              cylinder(r=fillet, h=shell);
            }
            
            //bottom rabbet cutout
            if(top==false)bottomRabbet(length, width, height, fillet, shell);
                
            //bottom hinge cutout
            if(top==false){
                translate([-length/2-shell,0,height])
                rotate([90,90,0])
                cylinder(d=2.3*shell+2*clearance, h=width-2*fillet+rib-8*shell+2*clearance, center=true); 
                
                translate([-length/2-shell,-2.25,height])
                rotate([90,90,0])
                cylinder(d=axis, h=width-2*fillet+rib-8*shell+2*clearance+4.5, center=true);   
            }
            
            //top hinge cutout
            if(top==true){
                translate([-length/2-shell,0,height])
                rotate([90,90,0])
                cylinder(d=2.3*shell+2*clearance, h=width-2*fillet-rib-8*shell+2*clearance, center=true);
                translate([-length/2-shell,0,height])
                rotate([90,90,0])
                cylinder(d=shell+2*clearance, h=width-2*fillet-6*shell, center=true);
                
                //cutout for filament axis
                translate([-length/2-shell,(width-2*fillet-rib-8.3*shell+clearance)/2,height])
                rotate([-90,0,0])cylinder(h=rib+5, d=axis);
                
                mirror([0,1,0])translate([-length/2-shell,(width-2*fillet-rib-8.3*shell+clearance)/2,height])
                rotate([-90,0,0])cylinder(h=rib+clearance, d=axis);
            }

        }

        //bottom hinge
        if(top==false){
            
            difference(){
                union(){
                    translate([-length/2-shell,0,height])
                    rotate([90,90,0])
                    cylinder(d=2.3*shell, h=width-2*fillet-rib-8*shell, center=true);
                
                    difference(){
                        union(){
                            translate([-length/2-shell-0.1*shell,0,height-2.5*shell])
                            cube([1.8*shell,width-2*fillet-rib-8*shell,5*shell], center=true);
                            
                            translate([-length/2-shell,0,height-3*shell])
                            cube([2*shell,width-2*fillet-rib-8*shell,4*shell], center=true);
                        }
                        
                        translate([-length/2-shell,0,height-5*shell])
                        rotate([0,-45,0])
                        cube([2*shell,width,10*shell], center=true);
                    }
                }
                
                
                translate([-length/2-shell,0,height])
                rotate([90,90,0])
                cylinder(d=axis, h=width-2*fillet-rib-8*shell+rib, center=true);
            }
            
        }
        
        //top hinge
        if(top==true){  
            topHingeSide(length, width, height, fillet, shell, clearance, rib, axis);
            mirror([0,1,0])topHingeSide(length, width, height, fillet, shell, clearance, rib, axis);
        }
        
        //top snap lid
        if(top==true){  
            difference(){
                union(){
                    translate([length/2+1.5*shell,0,height])
                    cube([shell,width-2*fillet-rib-8*shell-clearance,6*shell], center=true);
                    
                    translate([length/2+0.5*shell,0,height-2*shell])
                    cube([shell,width-2*fillet-rib-8*shell,4*shell], center=true);
                    
                    translate([length/2+1.1*shell,0,height+1.5*shell+2*clearance])
                    rotate([90,90,0])
                    cylinder(d=shell, h=width-2*fillet-rib-8*shell-clearance, center=true);
                }
                
                translate([length/2+shell,0,height-4*shell])
                rotate([0,45,0])
                cube([2*shell,width,10*shell], center=true);
                
                translate([length/2+shell,(width-2*fillet-rib-8*shell)/2,height+4*shell])
                rotate([45,0,0])
                cube([10*shell,3*shell,10*shell], center=true);
                
                translate([length/2+shell,-(width-2*fillet-rib-8*shell)/2,height+4*shell])
                rotate([-45,0,0])
                cube([10*shell,3*shell,10*shell], center=true);

                  
                translate([length/2+shell,0,height+4.8*shell])
                rotate([0,45,0])
                cube([3*shell,width,10*shell], center=true);
            }

        }
    } 
}


//helper module for top hinge
module topHingeSide(length, width, height, fillet, shell, clearance,rib, axis){
        difference(){
            union(){
                translate([-length/2-shell,(width/2-fillet-4*shell+0.5*clearance),height])
                rotate([90,90,0])
                cylinder(d=2.3*shell, h=rib-clearance, center=true);
                
                translate([-length/2-shell,(width/2-fillet-4*shell+0.5*clearance),height-2*shell])
                cube([2*shell,rib-clearance,4*shell], center=true);
                
            }
            
            
            
            translate([-length/2-shell,(width-2*fillet-rib-8.3*shell+clearance)/2,height])
            rotate([-90,0,0])cylinder(h=rib+1, d=axis);
                                            
            translate([-length/2-shell,0,height-4*shell])
            rotate([0,-45,0])
            cube([2*shell,width,10*shell], center=true);
        }

}

//helper module for bottom rabbet
module bottomRabbet(length, width, height, fillet, shell){
    translate([-length/2+fillet+shell, -width/2+fillet+shell,height-shell/8*7])
    difference(){
        minkowski()
        {
            cube([length-2*fillet-2*shell,width-2*fillet-2*shell,shell/3*2]);
            cylinder(r1=fillet+1.1*shell, r2=fillet+1.5*shell, h=shell/3);
        }
        minkowski()
        {
            cube([length-2*fillet-2*shell,width-2*fillet-2*shell,0.001]);
            cylinder(r1=fillet+0.9*shell,r2=fillet+0.5*shell, h=shell/3);
        }
        minkowski()
        {
            cube([length-2*fillet-2*shell,width-2*fillet-2*shell,shell/2+0.001]);
            cylinder(r=fillet+0.5*shell, h=shell/2);
        }
    }
}

//helper module for top rabbet
module topRabbet(length, width, height, fillet, shell){
    translate([-length/2+fillet+shell, -width/2+fillet+shell,height])
    difference(){
        minkowski()
        {
            cube([length-2*fillet-2*shell,width-2*fillet-2*shell,0.001]);
            cylinder(r1=fillet+1.5*shell,r2=fillet+1.1*shell, h=shell/2);
        }
        minkowski()
        {
            translate([0,0,-0.001])cube([length-2*fillet-2*shell,width-2*fillet-2*shell,0.105]);
            cylinder(r1=fillet+0.5*shell,r2=fillet+0.9*shell, h=shell/2);
        }
    }
}

//helper module for ribs
module oneRibY(length, width, height, fillet, shell, rib){
    intersection(){
        translate([-length/2+fillet+shell, -width/2+fillet+shell,0])
        minkowski()
        {
          cube([length-2*fillet-2*shell,width-2*fillet-2*shell,height-shell]);
          cylinder(r1=fillet+shell, r2=fillet+2*shell,h=shell);
        }

        translate([length/2-fillet-4*shell,0,1])
        cube([rib, 2*width, 2*height], center=true);
    }
}

//helper module for ribs
module oneRibX(length, width, height, fillet, shell, rib){
    intersection(){
        translate([-length/2+fillet+shell, -width/2+fillet+shell,0])
        minkowski()
        {
          cube([length-2*fillet-2*shell,width-2*fillet-2*shell,height-shell]);
          cylinder(r1=fillet+shell, r2=fillet+2*shell,h=shell);
        }

        translate([0,width/2-fillet-4*shell,1])
        cube([2*length, rib, 2*height], center=true);
    }
}







