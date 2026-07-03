// PiPBox by Lysyndre
//
// Author: https://makerworld.com/en/@lysyndre
// Link: https://makerworld.com/en/models/485147
//

/*[Main Dimensions]*/
// Total Length of the volume inside the box (mm)
Length  = 75; //[0:0.1:300]
// Total Width of the volume inside the box (mm)
Width   = 30; //[0:0.1:150]
// Total Heigth of the volume inside the box (mm)
Height  = 30; //[0:0.1:300]
// Radius of the inner corners (mm), Should not exceed half of the "Length" or "Width"
Radius  = 5; //[0:0.1:75]
//Outer Diameter of the hinge (mm), Should be smaller than "Height"
Hinge_Diameter  = 5; //[3:1:150]
//Should be smaller than ("Length" / "Hinge Diameter")
Hinge_Amount = 5; //[3:1:19]

/* [Hidden] */
wt  = 1.5;  //wall thickness
hg  = 0.5;  //gap tolerance
hcv = 0.5;  //end hinges chamger value
cr  = 69;   //circle refinement


l   = Length;
w   = Width;
h   = Height;
r   = Radius;
D   = Hinge_Diameter;
L   = l +2*wt;
W   = w +2*wt;
H   = h +2*wt;
R   = r +wt;
x   =R+D/2;     //x offset value
y   =R-L/2;     //y offset value
xi  =x+W-R;
yi  =0;

hs  = hg;
ha  = Hinge_Amount;
hr  = D/2;
hc  =((L+hg)/ha)-hg;
K   =H/2+hs;           //hypotenuse for tangent point calculation
tpx =hr*K/(sqrt((K^2)+(hr^2)));
tpy =hr*hr/(sqrt((K^2)+(hr^2)));
hp  =hr-hs;             //hinge peak length
hl  =hp+hc;             //total hinge length

module inner_section(){
    linear_extrude(h){
        translate([x,y])
        circle(r,$fn=cr);
        translate([x+w-2*r,y+0])
        circle(r,$fn=cr);
        translate([x+w-2*r,y+l-2*r])
        circle(r,$fn=cr);
        translate([x,y+l-2*r])
        circle(r,$fn=cr);
        polygon([
        [x,y-r],
        [x+w-2*r,y-r],
        [x+w-r,y],
        [x+w-r,y+l-2*r],
        [x+w-2*r,y+l-r],
        [x,y+l-r],
        [x-r,y+l-2*r],
        [x-r,y]]); 
    }
}
module outer_section(){
    linear_extrude(H/2){
        translate([x,y])
        circle(R,$fn=cr);
        translate([x+W-2*R,y])
        circle(R,$fn=cr);
        translate([x+W-2*R,y+L-2*R])
        circle(R,$fn=cr);
        translate([x,y+L-2*R])
        circle(R,$fn=cr);
        polygon([
        [x-R,y-R],
        [x+W-2*R,y-R],
        [x+W-R,y],
        [x+W-R,y+L-2*R],
        [x+W-2*R,y+L-R],
        [x-R,y+L-R]]);
    }
}
module box_clamp(){
    
    difference(){
        rotate([90,0,0])
    translate([0,0,-D/2])
        linear_extrude(D){
        polygon([
                [xi,        yi],
                [xi+2*wt,   yi],
                [xi+2*wt,   yi+H/2+wt],
                [xi-wt*2/3,     yi+H/2+3*wt],
                [xi+wt*2/3, yi+H/2+wt],
                [xi,        yi+H/2]]);
    }
    linear_extrude(H){
        translate([0,0,-D/2])
        polygon([
        [2*wt+W+D/2,0],
        [2*wt+W+D/2,-D/3],
        [W+D/2,-D],
        [2*wt+2*W,-D],
        [2*wt+2*W,D],
        [W+D/2,D],
        [2*wt+W+D/2,D/3],
        [2*wt+W+D/2,0],
        ]);
    }
    }
    
}
module clamp_hole(){
    rotate([90,0,0])
    translate([0,0,-D*3/4])
    linear_extrude(D*3/2){
            polygon([
            [xi,    yi+H/2-wt*11/3],
            [xi-wt, yi+H/2-wt*3],
            [xi,    yi+H/2-wt],
            [xi+wt, yi+H/2-wt],
            [xi+ wt, yi+H/2-wt*11/3]]);
        }
}
module hinge_m(){
    rotate([-90,0,0])
    translate([0,-H/2-hg,-L/2])
    linear_extrude(hc) {
        difference(){
            polygon([
            [hr,   0],
            [hr,   H/2+hs],
            [-tpx,   tpy]]);
            circle(hr-hs,$fn=cr);
        }
    }
    rotate([-90,0,0])
    translate([0,-H/2-hg,-L/2])
    rotate_extrude(angle=360,$fn=cr)
    polygon([
    [0,     0],
    [hr-hcv,0],
    [hr,    hcv],
    [hr,    hc],
    [hr-hs, hc],
    [0,     hl]]); //begining hinge
}


module hinge_f(){
    rotate([-90,0,0])
    translate([0,-H/2-hg,-L/2])
    translate([0,0,(hc+hg)*(ha-1)])
    linear_extrude(hc) {
        difference(){
            polygon([
            [hr,   0],
            [hr,   H/2+hs],
            [-tpx,   tpy]]);
            circle(hr-hs,$fn=cr);
        }
    }
    rotate([-90,0,0])
    translate([0,-H/2-hg,-L/2])
    translate([0,0,(hc+hg)*(ha-1)])
    rotate_extrude(angle=360,$fn=cr)
    polygon([
    [0,     hp],
    [hr-hs, 0],
    [hr,    0],
    [hr,    hc-hcv],
    [hr-hs, hc],
    [0,     hc]]);   //final hinge
  
}
module hinge_mid_o(){
    for(i=[1:ha-2]){    //middle hinge(s) loop (even ones)
    if(i%2!=0){
        rotate([-90,0,0])
        translate([0,-H/2-hg,-L/2])
        translate([0,0,(hc+hg)*i])
        rotate_extrude(angle=360,$fn=cr)
        polygon(points=[[0,hp],[hr-hs,0],[hr,0],[hr,hc],[hr-hs,hc],[0,hl]]);
        rotate([-90,0,0])
        translate([0,-H/2-hg,-L/2])
        translate([0,0,(hc+hg)*i])
        linear_extrude(hc) {
            difference(){
                polygon([[hr,0],[hr,H/2+hs],[-tpx,tpy]]);
                circle(hr-hs,$fn=cr);
                }
        }
    }
}
}
module hinge_mid_e(){
    for(i=[1:ha-2]){    //middle hinge(s) loop (even ones)
    if(i%2==0){
        rotate([-90,0,0])
        translate([0,-H/2-hg,-L/2])
        translate([0,0,(hc+hg)*i])
        rotate_extrude(angle=360,$fn=cr)
        polygon(points=[[0,hp],[hr-hs,0],[hr,0],[hr,hc],[hr-hs,hc],[0,hl]]);
        rotate([-90,0,0])
        translate([0,-H/2-hg,-L/2])
        translate([0,0,(hc+hg)*i])
        linear_extrude(hc) {
            difference(){
                polygon([[hr,0],[hr,H/2+hs],[-tpx,tpy]]);
                circle(hr-hs,$fn=cr);
                }
        }
    }
}
}
module base_box(type,color){
    color(color){
        group(){
            if(type=="m"){
                box_clamp();
                hinge_mid_o();
                if(ha%2==0){
                    hinge_f();
                }
                difference(){
                    outer_section();
                    translate([0,0,wt]) 
                    inner_section();  
                }
            }
            else if(type=="f"){
                hinge_m();
                hinge_mid_e();
                if(ha%2!=0){
                    hinge_f();
                }
                difference(){
                    outer_section();
                    clamp_hole();
                    translate([0,0,wt]) 
                    inner_section();
                }
            }
        }
    }
}

//

    
base_box("m","cyan");
mirror([1,0,0]) base_box("f","magenta");
