// Version: 1.6
// From https://www.TheEngine.com
// Auhor: kevin@theengine.com
//        Links https://github.com/donnay
//        Links https://www.instagram.com/kevindclarke/
// Contributions: https://www.fiverr.com/veltaf
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International 

//Version Notes
// 1.0 Initial release
// 1.1 Added back & parameters
// 1.2 Organized the parameters & clean up the case
// 1.3 Added Logo parameters (not sure if they will work online
// 1.4 Corrected missing logo on flat door
// 1.5 Added option to hide the rails
// 1.6 Set Back thickness = Wall_thickness - Back_Inset_depth (back = cube thickness)

quality = $preview ? 25 : 100;  //50 :200

/* [Box] */
show_cube = true; //[true:false]
cube_width = 168;
cube_depth = 168;
cube_height = 168;
wall_thickness = 2;

show_rails = true; //[true:false]
rail_thickness=1.2; //[0:0.1:10]
rail_radius=35; //[30:1:90]
rail_gap=6; //[0:0.1:10]
rail_height = 5; //[0:0.1:10]

/* [Back] */
show_back = true; 
back_inset_depth = 1; //[0:0.1:5]
back_width = cube_width - wall_thickness*2;
back_height = cube_height - wall_thickness*2;

/* [Door] */
show_door = true; //[true:false]
// If full width door,set value to 0mm
insert_lenght = 0;
insert_gap = 0; //[0:0.1:10]
insert_quantity =20; //[0:0.1:100]

door_thickness = 1.7; //[0:0.1:10]
door_width = cube_width-2*insert_lenght-2*wall_thickness-2*insert_gap;
door_height = cube_height+2*wall_thickness;
door_height_offset = 8; //[0:1:10]
door_clearance = 2; //[1:.1:4]
door_widthf = door_width-door_clearance;
handle_width = 20;
handle_height = 6;
handle_depth = 6;
door_Pattern = "slotter";  //["slotter", "flat"]

/* [Door pattern] */
door_slot_columns = 4; //[2:1: 10]
door_slot_spacing = 1.5; //[0:0.1:10]
door_slot_width = 3; //[0:0.1:10]
door_slot_depth = 2; //[2:0.1:3.8]

/* [Logo] */
show_logo_door = true; //[true:false]
show_logo_back = true; //[true:false]
logo_file = "logo.svg";
logo_height = 5; //[0:.1:10]
logo_door_inset = 0.1; //[0.0:0.1:1.9]
// Percentage 100 = 100%
logo_scale = 100; //[10:10:999]
logo_center = true;
logo_width_mm = 68; //[0:1:2000]
logo_length_mm = 54; //0:1:2000]
logo_rotate_deg = 180; //[0:1:360];

//added slotter code here
// Library: slotter
// Version: unknown
// Author: Knochi
// Author Link https://cults3d.com/en/users/Knochi/3d-models
// License: https://cults3d.com/en/licenses#cc_by

difference(){
    //cube([40,40,3],true);
    //slotter(40,40,1,3,2,3);
}

module slotter(linkW, linkL, columns, sheetT, slotW, beamW, inset) { //linkage length/width, sheet thickness, clearance, beam width
    $fn=50;
    col=columns;
    fudge=0.1;
    //L = 2*length+2*thickn;
    row = floor((linkW-beamW-1)/(slotW+beamW)-1);
    slotL = linkL/col-beamW*2;
    echo("length of link", linkL);
    echo("link rows",row);
    echo("slot Len",slotL);
    
    intersection(){
        translate([-linkL/2,-(row)*(slotW+beamW)/2,inset])
        
        for (j=[0:col]){ //colums
        //echo("j",j);
            for (i=[0:row]){
            //echo("row",i,i%2);
                translate([(beamW*2+slotL)*j+(slotL/2+beamW)*(i%2),i*(beamW+slotW),0])
                
                union(){
                    translate([-(slotL-slotW)/2,0,0]) cylinder(h=sheetT+fudge,d=slotW,center=true);
                    translate([(slotL-slotW)/2,0,0]) cylinder(h=sheetT+fudge,d=slotW,center=true);
                    cube([slotL-slotW,slotW,sheetT+fudge],true);
                    
                    if ((i%2) && (j==0) ){ 
                        translate([-(slotL-slotW)/2,0,0])
                        difference(){
                            cylinder(h=sheetT+fudge,d=slotW*3+beamW*2,center=true);
                            cylinder(h=sheetT+fudge*2,d=slotW+beamW*2,center=true);
                            translate([(slotW*3+beamW*2)/2,0,0]) cube([slotW*3+beamW*2+fudge,slotW*3+beamW*2+fudge,sheetT+fudge*2],true);
                            if (i==row) translate([0,(slotW*3+beamW*2)/2,0]) //if last row
                                            cube([slotW*3+beamW*2+fudge,slotW*3+beamW*2+fudge,sheetT+fudge*2],true);
                        }
                    }
                    if ((i%2) && (j==col-1)){ 
                        translate([(slotL-slotW)/2,0,0])
                        difference(){
                            cylinder(h=sheetT+fudge,d=slotW*3+beamW*2,center=true);
                            cylinder(h=sheetT+fudge*2,d=slotW+beamW*2,center=true);
                            translate([(-slotW*3-beamW*2)/2,0,0]) cube([slotW*3+beamW*2+fudge,slotW*3+beamW*2+fudge,sheetT+fudge*2],true);
                            if (i==row) translate([0,(slotW*3+beamW*2)/2,0]) //if last row
                                            cube([slotW*3+beamW*2+fudge,slotW*3+beamW*2+fudge,sheetT+fudge*2],true);
                        }
                    }
                    if (i==0) { //if first row
                        if (j==col) //if last column
                            translate([-beamW,-slotW/2-beamW,0])
                                difference(){
                                    translate([0,0,-(sheetT+fudge)/2]) cube([beamW+fudge,beamW+fudge,sheetT+fudge]);
                                    cylinder(h=sheetT+fudge*2,d=beamW*2,center=true);
                                }
                        if (j==0) //if first column
                            translate([beamW,-slotW/2-beamW,0])
                                difference(){
                                    translate([-beamW-fudge,0,-(sheetT+fudge)/2]) cube([beamW+fudge,beamW+fudge,sheetT+fudge]);
                                    cylinder(h=sheetT+fudge*2,d=beamW*2,center=true);
                                }
                    }
                    
                    if ((i==row)&& !(i%2)){ //if last row is odd
                        if (j==col) //if last column
                            translate([-beamW,slotW/2+beamW,0])
                                difference(){
                                    translate([0,-beamW-fudge,-(sheetT+fudge)/2]) cube([beamW+fudge,beamW+fudge,sheetT+fudge]);
                                    cylinder(h=sheetT+fudge*2,d=beamW*2,center=true);
                                }
                        if (j==0) //if first column
                            translate([beamW,slotW/2+beamW,0])
                                difference(){
                                    translate([-beamW-fudge,-beamW-fudge,-(sheetT+fudge)/2]) cube([beamW+fudge,beamW+fudge,sheetT+fudge]);
                                    cylinder(h=sheetT+fudge*2,d=beamW*2,center=true);
                                }
                    }
                    
                
                }
      
            }
        }
   cube([linkL+fudge,linkW+fudge,sheetT+fudge],true); //cut slots
    }
}
// end of added slotter code

// add ployround code

// Library: round-anything
// Version: 1.0
// Author: IrevDev
// Contributors: TLC123
// Copyright: 2020
// License: MIT

function polyRound(radiipoints,fn=5,mode=0)=
  /*Takes a list of radii points of the format [x,y,radius] and rounds each point
    with fn resolution
    mode=0 - automatic radius limiting - DEFAULT
    mode=1 - Debug, output radius reduction for automatic radius limiting
    mode=2 - No radius limiting*/
  let(
    p=getpoints(radiipoints), //make list of coordinates without radii
    Lp=len(p),
    //remove the middle point of any three colinear points, otherwise adding a radius to the middle of a straigh line causes problems
    radiiPointsWithoutTrippleColinear=[
      for(i=[0:len(p)-1]) if(
        // keep point if it isn't colinear or if the radius is 0
        !isColinear(
          p[listWrap(i-1,Lp)],
          p[listWrap(i+0,Lp)],
          p[listWrap(i+1,Lp)]
        )||
        p[listWrap(i+0,Lp)].z!=0
      ) radiipoints[listWrap(i+0,Lp)] 
    ],
    newrp2=processRadiiPoints(radiiPointsWithoutTrippleColinear),
    plusMinusPointRange=mode==2?1:2,
    temp=[
      for(i=[0:len(newrp2)-1]) //for each point in the radii array
      let(
        thepoints=[for(j=[-plusMinusPointRange:plusMinusPointRange])newrp2[listWrap(i+j,len(newrp2))]],//collect 5 radii points
        temp2=mode==2?round3points(thepoints,fn):round5points(thepoints,fn,mode)
      )
      mode==1?temp2:newrp2[i][2]==0?
        [[newrp2[i][0],newrp2[i][1]]]: //return the original point if the radius is 0
        CentreN2PointsArc(temp2[0],temp2[1],temp2[2],0,fn) //return the arc if everything is normal
    ]
  )
  [for (a = temp) for (b = a) b];//flattern and return the array

function round5points(rp,fn,debug=0)=
	rp[2][2]==0&&debug==0?[[rp[2][0],rp[2][1]]]://return the middle point if the radius is 0
	rp[2][2]==0&&debug==1?0://if debug is enabled and the radius is 0 return 0
	let(
    p=getpoints(rp), //get list of points
    r=[for(i=[1:3]) abs(rp[i][2])],//get the centre 3 radii
    //start by determining what the radius should be at point 3
    //find angles at points 2 , 3 and 4
    a2=cosineRuleAngle(p[0],p[1],p[2]),
    a3=cosineRuleAngle(p[1],p[2],p[3]),
    a4=cosineRuleAngle(p[2],p[3],p[4]),
    //find the distance between points 2&3 and between points 3&4
    d23=pointDist(p[1],p[2]),
    d34=pointDist(p[2],p[3]),
    //find the radius factors
    F23=(d23*tan(a2/2)*tan(a3/2))/(r[0]*tan(a3/2)+r[1]*tan(a2/2)),
    F34=(d34*tan(a3/2)*tan(a4/2))/(r[1]*tan(a4/2)+r[2]*tan(a3/2)),
    newR=min(r[1],F23*r[1],F34*r[1]),//use the smallest radius
    //now that the radius has been determined, find tangent points and circle centre
    tangD=newR/tan(a3/2),//distance to the tangent point from p3
      circD=newR/sin(a3/2),//distance to the circle centre from p3
    //find the angle from the p3
    an23=getAngle(p[1],p[2]),//angle from point 3 to 2
    an34=getAngle(p[3],p[2]),//angle from point 3 to 4
    //find tangent points
    t23=[p[2][0]-cos(an23)*tangD,p[2][1]-sin(an23)*tangD],//tangent point between points 2&3
    t34=[p[2][0]-cos(an34)*tangD,p[2][1]-sin(an34)*tangD],//tangent point between points 3&4
    //find circle centre
    tmid=getMidpoint(t23,t34),//midpoint between the two tangent points
    anCen=getAngle(tmid,p[2]),//angle from point 3 to circle centre
    cen=[p[2][0]-cos(anCen)*circD,p[2][1]-sin(anCen)*circD]
  )
    //circle center by offseting from point 3
    //determine the direction of rotation
	debug==1?//if debug in disabled return arc (default)
    (newR-r[1]):
	[t23,t34,cen];

function round3points(rp,fn)=
  rp[1][2]==0?[[rp[1][0],rp[1][1]]]://return the middle point if the radius is 0
	let(
    p=getpoints(rp), //get list of points
	  r=rp[1][2],//get the centre 3 radii
    ang=cosineRuleAngle(p[0],p[1],p[2]),//angle between the lines
    //now that the radius has been determined, find tangent points and circle centre
	  tangD=r/tan(ang/2),//distance to the tangent point from p2
    circD=r/sin(ang/2),//distance to the circle centre from p2
    //find the angles from the p2 with respect to the postitive x axis
    angleFromPoint1ToPoint2=getAngle(p[0],p[1]),
    angleFromPoint2ToPoint3=getAngle(p[2],p[1]),
    //find tangent points
    t12=[p[1][0]-cos(angleFromPoint1ToPoint2)*tangD,p[1][1]-sin(angleFromPoint1ToPoint2)*tangD],//tangent point between points 1&2
    t23=[p[1][0]-cos(angleFromPoint2ToPoint3)*tangD,p[1][1]-sin(angleFromPoint2ToPoint3)*tangD],//tangent point between points 2&3
    //find circle centre
    tmid=getMidpoint(t12,t23),//midpoint between the two tangent points
    angCen=getAngle(tmid,p[1]),//angle from point 2 to circle centre
    cen=[p[1][0]-cos(angCen)*circD,p[1][1]-sin(angCen)*circD] //circle center by offseting from point 2 
  )
	[t12,t23,cen];

function is90or270(ang)=ang==90?1:ang==270?1:0;

function CWorCCW(p)=
	let(
    Lp=len(p),
	  e=[for(i=[0:Lp-1]) 
      (p[listWrap(i+0,Lp)].x-p[listWrap(i+1,Lp)].x)*(p[listWrap(i+0,Lp)].y+p[listWrap(i+1,Lp)].y)
    ]
  )  
  sign(sum(e));

function CentreN2PointsArc(p1,p2,cen,mode=0,fn)=
  /* This function plots an arc from p1 to p2 with fn increments using the cen as the centre of the arc.
  the mode determines how the arc is plotted
  mode==0, shortest arc possible 
  mode==1, longest arc possible
  mode==2, plotted clockwise
  mode==3, plotted counter clockwise
  */
	let(
    isCWorCCW=CWorCCW([cen,p1,p2]),//determine the direction of rotation
    //determine the arc angle depending on the mode
    p1p2Angle=cosineRuleAngle(p2,cen,p1),
    arcAngle=
      mode==0?p1p2Angle:
      mode==1?p1p2Angle-360:
      mode==2&&isCWorCCW==-1?p1p2Angle:
      mode==2&&isCWorCCW== 1?p1p2Angle-360:
      mode==3&&isCWorCCW== 1?p1p2Angle:
      mode==3&&isCWorCCW==-1?p1p2Angle-360:
      cosineRuleAngle(p2,cen,p1),
    r=pointDist(p1,cen),//determine the radius
	  p1Angle=getAngle(cen,p1) //angle of line 1
  )
  [for(i=[0:fn])
  let(angleIncrement=(arcAngle/fn)*i*isCWorCCW)
  [cos(p1Angle+angleIncrement)*r+cen.x,sin(p1Angle+angleIncrement)*r+cen.y]];

function translateRadiiPoints(radiiPoints,tran=[0,0],rot=0)=
	[for(i=radiiPoints) 
		let(
      a=getAngle([0,0],[i.x,i.y]),//get the angle of the this point
		  h=pointDist([0,0],[i.x,i.y]) //get the hypotenuse/radius
    )
		[h*cos(a+rot)+tran.x,h*sin(a+rot)+tran.y,i.z]//calculate the point's new position
	];

module round2d(OR=3,IR=1){
  offset(OR,$fn=100){
    offset(-IR-OR,$fn=100){
      offset(IR,$fn=100){
        children();
      }
    }
  }
}

function mirrorPoints(radiiPoints,rot=0,endAttenuation=[0,0])= //mirrors a list of points about Y, ignoring the first and last points and returning them in reverse order for use with polygon or polyRound
  let(
    a=translateRadiiPoints(radiiPoints,[0,0],-rot),
    temp3=[for(i=[0+endAttenuation[0]:len(a)-1-endAttenuation[1]])
      [a[i][0],-a[i][1],a[i][2]]
    ],
    temp=translateRadiiPoints(temp3,[0,0],rot),
    temp2=revList(temp3)
  )    
  concat(radiiPoints,temp2);

function processRadiiPoints(rp)=
  [for(i=[0:len(rp)-1])
    processRadiiPoints2(rp,i)
  ];

function processRadiiPoints2(list,end=0,idx=0,result=0)=
  idx>=end+1?result:
  processRadiiPoints2(list,end,idx+1,relationalRadiiPoints(result,list[idx]));

function cosineRuleBside(a,c,C)=c*cos(C)-sqrt(sq(a)+sq(c)+sq(cos(C))-sq(c));

function absArelR(po,pn)=
  let(
    th2=atan(po[1]/po[0]),
    r2=sqrt(sq(po[0])+sq(po[1])),
    r3=cosineRuleBside(r2,pn[1],th2-pn[0])
  )
  [cos(pn[0])*r3,sin(pn[0])*r3,pn[2]];

function relationalRadiiPoints(po,pi)=
  let(
    p0=pi[0],
    p1=pi[1],
    p2=pi[2],
    pv0=pi[3][0],
    pv1=pi[3][1],
    pt0=pi[3][2],
    pt1=pi[3][3],
    pn=
      (pv0=="y"&&pv1=="x")||(pv0=="r"&&pv1=="a")||(pv0=="y"&&pv1=="a")||(pv0=="x"&&pv1=="a")||(pv0=="y"&&pv1=="r")||(pv0=="x"&&pv1=="r")?
        [p1,p0,p2,concat(pv1,pv0,pt1,pt0)]:
        [p0,p1,p2,concat(pv0,pv1,pt0,pt1)],
    n0=pn[0],
    n1=pn[1],
    n2=pn[2],
    nv0=pn[3][0],
    nv1=pn[3][1],
    nt0=pn[3][2],
    nt1=pn[3][3],
    temp=
      pn[0]=="l"?
        [po[0],pn[1],pn[2]]
      :pn[1]=="l"?
        [pn[0],po[1],pn[2]]
      :nv0==undef?
        [pn[0],pn[1],pn[2]]//abs x, abs y as default when undefined
      :nv0=="a"?
        nv1=="r"?
          nt0=="a"?
            nt1=="a"||nt1==undef?
              [cos(n0)*n1,sin(n0)*n1,n2]//abs angle, abs radius
            :absArelR(po,pn)//abs angle rel radius
          :nt1=="r"||nt1==undef?
            [po[0]+cos(pn[0])*pn[1],po[1]+sin(pn[0])*pn[1],pn[2]]//rel angle, rel radius 
          :[pn[0],pn[1],pn[2]]//rel angle, abs radius
        :nv1=="x"?
          nt0=="a"?
            nt1=="a"||nt1==undef?
              [pn[1],pn[1]*tan(pn[0]),pn[2]]//abs angle, abs x
            :[po[0]+pn[1],(po[0]+pn[1])*tan(pn[0]),pn[2]]//abs angle rel x
            :nt1=="r"||nt1==undef?
              [po[0]+pn[1],po[1]+pn[1]*tan(pn[0]),pn[2]]//rel angle, rel x 
            :[pn[1],po[1]+(pn[1]-po[0])*tan(pn[0]),pn[2]]//rel angle, abs x
          :nt0=="a"?
            nt1=="a"||nt1==undef?
              [pn[1]/tan(pn[0]),pn[1],pn[2]]//abs angle, abs y
            :[(po[1]+pn[1])/tan(pn[0]),po[1]+pn[1],pn[2]]//abs angle rel y
          :nt1=="r"||nt1==undef?
            [po[0]+(pn[1]-po[0])/tan(90-pn[0]),po[1]+pn[1],pn[2]]//rel angle, rel y 
          :[po[0]+(pn[1]-po[1])/tan(pn[0]),pn[1],pn[2]]//rel angle, abs y
      :nv0=="r"?
        nv1=="x"?
          nt0=="a"?
            nt1=="a"||nt1==undef?
              [pn[1],sign(pn[0])*sqrt(sq(pn[0])-sq(pn[1])),pn[2]]//abs radius, abs x
            :[po[0]+pn[1],sign(pn[0])*sqrt(sq(pn[0])-sq(po[0]+pn[1])),pn[2]]//abs radius rel x
          :nt1=="r"||nt1==undef?
            [po[0]+pn[1],po[1]+sign(pn[0])*sqrt(sq(pn[0])-sq(pn[1])),pn[2]]//rel radius, rel x 
          :[pn[1],po[1]+sign(pn[0])*sqrt(sq(pn[0])-sq(pn[1]-po[0])),pn[2]]//rel radius, abs x
        :nt0=="a"?
          nt1=="a"||nt1==undef?
            [sign(pn[0])*sqrt(sq(pn[0])-sq(pn[1])),pn[1],pn[2]]//abs radius, abs y
          :[sign(pn[0])*sqrt(sq(pn[0])-sq(po[1]+pn[1])),po[1]+pn[1],pn[2]]//abs radius rel y
        :nt1=="r"||nt1==undef?
          [po[0]+sign(pn[0])*sqrt(sq(pn[0])-sq(pn[1])),po[1]+pn[1],pn[2]]//rel radius, rel y 
        :[po[0]+sign(pn[0])*sqrt(sq(pn[0])-sq(pn[1]-po[1])),pn[1],pn[2]]//rel radius, abs y
      :nt0=="a"?
        nt1=="a"||nt1==undef?
          [pn[0],pn[1],pn[2]]//abs x, abs y
        :[pn[0],po[1]+pn[1],pn[2]]//abs x rel y
      :nt1=="r"||nt1==undef?
        [po[0]+pn[0],po[1]+pn[1],pn[2]]//rel x, rel y 
      :[po[0]+pn[0],pn[1],pn[2]]//rel x, abs y
  )
  temp;

function invtan(run,rise)=
  let(a=abs(atan(rise/run)))
  rise==0&&run>0?
    0:rise>0&&run>0?
    a:rise>0&&run==0?
    90:rise>0&&run<0?
    180-a:rise==0&&run<0?
    180:rise<0&&run<0?
    a+180:rise<0&&run==0?
    270:rise<0&&run>0?
    360-a:"error";

function cosineRuleAngle(p1,p2,p3)=
  let(
    p12=abs(pointDist(p1,p2)),
    p13=abs(pointDist(p1,p3)),
    p23=abs(pointDist(p2,p3))
  )
  acos((sq(p23)+sq(p12)-sq(p13))/(2*p23*p12));

function sum(list, idx = 0, result = 0) = 
	idx >= len(list) ? result : sum(list, idx + 1, result + list[idx]);

function sq(x)=x*x;
function getGradient(p1,p2)=(p2.y-p1.y)/(p2.x-p1.x);
function getAngle(p1,p2)=p1==p2?0:invtan(p2[0]-p1[0],p2[1]-p1[1]);
function getMidpoint(p1,p2)=[(p1[0]+p2[0])/2,(p1[1]+p2[1])/2]; //returns the midpoint of two points
function pointDist(p1,p2)=sqrt(abs(sq(p1[0]-p2[0])+sq(p1[1]-p2[1]))); //returns the distance between two points
function isColinear(p1,p2,p3)=getGradient(p1,p2)==getGradient(p2,p3)?1:0;//return 1 if 3 points are colinear
module polyline(p, width=0.3) {
  for(i=[0:max(0,len(p)-1)]){
    color([i*1/len(p),1-i*1/len(p),0,0.5])line(p[i],p[listWrap(i+1,len(p) )],width);
  }
} // polyline plotter
module line(p1, p2 ,width=0.3) { // single line plotter
  hull() {
    translate(p1){
      circle(width);
    }
    translate(p2){
      circle(width);
    }
  }
}

function getpoints(p)=[for(i=[0:len(p)-1])[p[i].x,p[i].y]];// gets [x,y]list of[x,y,r]list
function listWrap(x,x_max=1,x_min=0) = (((x - x_min) % (x_max - x_min)) + (x_max - x_min)) % (x_max - x_min) + x_min; // wraps numbers inside boundaries
function rnd(a = 1, b = 0, s = []) = 
  s == [] ? 
    (rands(min(a, b), max(   a, b), 1)[0]):(rands(min(a, b), max(a, b), 1, s)[0]); // nice rands wrapper 
    
    //cube(10);

// end of added ployround code

module Box(){
    
    difference() {
        cube([cube_width, cube_depth,cube_height], center = false);
        translate([wall_thickness,-wall_thickness,wall_thickness]) 
        cube([
            cube_width-2*wall_thickness, cube_depth-wall_thickness+10, cube_height-2*wall_thickness,
            ], 
            center = false);
    }
}

module Rail(){
   
   linear_extrude(rail_height) 
   polygon(
        polyRound(
            radiipoints = [
                // [X,Y, radius]
                [wall_thickness,cube_depth-wall_thickness/2, 0], 
                [cube_height-wall_thickness,cube_depth-wall_thickness/2,rail_radius],
                [cube_height-wall_thickness,wall_thickness,0],
                [cube_height-wall_thickness-rail_thickness,wall_thickness,0],
                [cube_height-wall_thickness-rail_thickness,cube_depth-wall_thickness/2-rail_thickness,rail_radius],
                [wall_thickness-rail_thickness,cube_depth-wall_thickness/2-rail_thickness, 0], 
            ], 
            fn = quality, 
            mode = 0
        )
    );    
    
    linear_extrude(rail_height) 
    polygon(
        polyRound(
            radiipoints = [
                // [X,Y, radius]
                [wall_thickness,cube_depth-wall_thickness/2-rail_gap, 0], 
                [cube_height-wall_thickness-rail_gap,cube_depth-wall_thickness/2-rail_gap,rail_radius],
                [cube_height-wall_thickness-rail_gap,wall_thickness,0],
                [cube_height-wall_thickness-rail_thickness-rail_gap,wall_thickness,0],
                [cube_height-wall_thickness-rail_thickness-rail_gap,cube_depth-wall_thickness/2-rail_thickness-rail_gap,rail_radius],
                [wall_thickness-rail_thickness,cube_depth-wall_thickness/2-rail_thickness-rail_gap, 0], 
            ], 
            fn = quality, 
            mode = 0
        )
    );     
}

module RailAssembly(){

    // Right rail when regarding in front of the opened box
    translate([wall_thickness+rail_height,0,0]) 
    rotate([0,-90,0]) 
    Rail();

    // Left rail when regarding in front of the opened box
    translate([cube_width-wall_thickness,0,0]) 
    rotate([0,-90,0]) 
    Rail();

}

module BoxAssembly(){

  Box();
  if(true == show_rails){
    RailAssembly();
    } else {
    // no rails
    }
}

module DoorInsert(){

 if ("flat" == door_Pattern){
  
  translate([-insert_lenght,door_thickness/2,door_thickness/2])  
   rotate([90,90,90]) 
   cylinder(h = insert_lenght, r = door_thickness/2, center = false,$fn=quality);
  } else {
    // nothing  
    }
    }

module DoorHandle(){

    
    translate([door_widthf/2-handle_width/2,door_height-handle_height+handle_depth,0]) 
    cube([handle_width,handle_height/2,handle_depth]);

}

module Door(){


    cube([door_widthf,door_height+door_height_offset,door_thickness]);

    if(0 < insert_quantity){
        DoorInsert();
        translate([door_widthf+insert_lenght-door_clearance,0,0]) 
        DoorInsert();
    } else {

    // nothing 
    }

    for(i=[door_height/(insert_quantity-1):door_height/(insert_quantity-1):door_height]){
        translate([0,i-door_thickness,0]) 
        DoorInsert();
        translate([door_widthf+insert_lenght-door_clearance,i-door_thickness,0]) 
        DoorInsert();
        }
    
}

module Logo (){

    if (true == logo_center)
    {
            logo_X_center = (cube_width/2)-(logo_width_mm*2);
            logo_Y_center = (cube_depth/2)-(logo_length_mm*2);
            translate([logo_X_center,logo_Y_center,0])
            linear_extrude (height=logo_height) 
            //rotate([0,0,logo_rotate_deg])
            scale([logo_scale/100,logo_scale/100,0])  
            { import(logo_file); }
            
    } else {
            
            translate([logo_width_mm,logo_length_mm,0])
            linear_extrude (height=logo_height) 
            scale([logo_scale/100,logo_scale/100,0])  
            //rotate([0,0,logo_rotate_deg])
            { import(logo_file); }
            
}
}


module DoorAssembly(){


    if ("slotter" == door_Pattern){
        difference() {

            Door();
            translate([door_widthf/2,door_height/2,0]) 
            slotter(
                linkW = door_height, 
                linkL = (door_widthf), 
                columns = door_slot_columns, 
                sheetT = 4,
                slotW = door_slot_spacing, 
                beamW = door_slot_width,
                inset = door_slot_depth
            );
        }
    
    } else if ("flat" == door_Pattern){
        
    Door();
    } 
        if (true == show_logo_door) 
        {
        translate([-door_height_offset,0,logo_height-logo_door_inset]) // offset for BambuStudio
        Logo();
        } else {
            // no logo
        }
    DoorHandle();
}

module main(){
    
    // Box   ----------------------------------
    if(show_cube==true)
    {
    BoxAssembly();
    }

    // Door   ----------------------------------
    if(show_door==true)
    {
    translate([door_widthf*1.5,0,0]) 
    translate([insert_lenght+wall_thickness+insert_gap,0,0])
    DoorAssembly();
        
    }
    
    // Back   ----------------------------------
    if(show_back==true)
    {
    translate([door_widthf*1.5,door_widthf*1.5,0]) 
    translate([insert_lenght+wall_thickness+insert_gap,0,0])
    
    union() {
        cube([cube_width,cube_height,wall_thickness-back_inset_depth]);
        translate([wall_thickness,wall_thickness,wall_thickness-back_inset_depth])
        cube([back_width,back_height,back_inset_depth]);
        
        if (true == show_logo_back) {       
                translate([0,0,-0.1]) // offset to allow the logo to be coloured in BambuStudio
                Logo();
            } else {
                // No Logo
            }
        };
    }
}
    

main();