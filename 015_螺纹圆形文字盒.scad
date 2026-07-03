echo(version=version());

/* [Box Options] */
Diameter=40;
Height=20;
Type= "Text";//[Text,Circle,Emoji,None]
Emoji_bottom=false;

/* [Circle and Text Options] */
Text="TEXT";
Top_special_caracter="♥"; //[♥,☺,☻,☼,♀,♂,♠,♣,♦,♪,♫,♯,◙,●,◊,◄,■,]
Text_Size=Diameter/10;
//colors doesn't show in preview, don't forget to paint the faces in bambu
Text_and_Cirle="Hollowed";//[Coloured,Hollowed]
Bottom_special_character="♥"; //[♥,☺,☻,☼,♀,♂,♠,♣,♦,♪,♫,♯,◙,●,◊,◄,■,]


n=Diameter/2;

//Designed by Benoit Perocheau
// License: CC-Attribution-Noncommercial-Share Alike

//Library 
{
    stddivs=50;

module thread_for_screw(diameter, length)
{
stdpitch=get_std_pitch(diameter);
thread_for_screw_cuiso_tec(diameter,length,stdpitch,divdelta=stddivs);
//echo(diameter);echo(stdpitch);
}

module thread_for_nut(diameter, length, usrclearance=0)
{
stdpitch=get_std_pitch(diameter);
stdclearance=get_std_clearance(diameter);

thread_for_nut_cuiso_tec
(diameter+stdclearance+usrclearance,length,stdpitch,divdelta=stddivs,entry=1);
    
//echo(diameter);echo(stdpitch);echo(stdclearance+usrclearance);
}


//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
function get_std_pitch(diam) = 
lookup(diam,[[3,0.5],[4,0.7],[5,0.8],[6,1.0],[8,1.25],[10,1.5],
[12,1.75],[14,2.0],[16,2.0],[18,2.5],[20,2.5],[22,2.5],[24,3.0]
]);

function get_std_clearance(diam) = 
lookup(diam,[[3,0.4],[4,0.4],[5,0.5],[6,0.6],[8,0.6],[10,0.6],
[12,0.7],[14,0.7],[16,0.7],[18,0.7],[20,0.8],[22,0.8],[24,0.8]
]);
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
module thread_for_screw_cuiso_tec(diameter,lenght,pitch,divdelta){
delta=360/divdelta;
intersection(){
cubointter(long=lenght,pitch=pitch,diameter=diameter,divdeltacube=divdelta);
rosca(long=lenght,p=pitch,delta=delta,diameter=diameter);
}
//#cylinder(d=diameter,h=lenght,$fn=100);
}

module thread_for_nut_cuiso_tec(diameter,lenght,pitch,divdelta,entry){
delta=360/divdelta;
translate([0,0,-0.001])
intersection(){
rosca(long=lenght+0.002,p=pitch,delta=delta,diameter=diameter,nut=1);
cubointter_nut(lenght+0.002,pitch,diameter);
}
if(entry==1){translate([0,0,-0.001])cubointter_nut_entry(lenght+0.002,pitch,diameter,divdeltacube=divdelta);}
//#cylinder(d=diameter,h=lenght,$fn=100);
}

module cubointter(long,pitch,diameter,divdeltacube)
{
longcube=long-pitch;
translate([0,0,longcube/2+pitch/2])cube([diameter,diameter,longcube],center=true);
translate([0,0,longcube+pitch/2])
cylinder(d1=diameter,d2=diameter-2*pitch*0.866,h=pitch/2, $fn=divdeltacube);
cylinder(d2=diameter,d1=diameter-2*pitch*0.866,h=pitch/2, $fn=divdeltacube);
}

module cubointter_nut(long,pitch,diameter)
{
longcube=long;
translate([0,0,longcube/2])cube([diameter,diameter,longcube],center=true);
}

module cubointter_nut_entry(long,pitch,diameter,divdeltacube)
{
longcube=long-0.6;
translate([0,0,longcube])
cylinder(d2=diameter+0.4,d1=diameter,h=0.6, $fn=divdeltacube);
cylinder(d1=diameter+0.4,d2=diameter,h=0.6, $fn=divdeltacube);
}

module rosca(long,p,delta,diameter,nut=0)
{
vueltas=round(long/p+0.5)+1;
translate([0,0,-p/4])
for(v = [0 : 1 : vueltas-1])
translate([0,0,v*p])
vuelta(p=p,delta=delta,diameter=diameter,nut=nut);
}

module vuelta(p,delta,diameter,nut)
{
medio(p=p,delta=delta,diameter=diameter,nut=nut);

translate([0,0.001,0])
rotate([0,180,180])
medio(p=p,delta=delta,diameter=diameter,nut=nut);
}

module medio(p,delta,diameter,nut)
{
if(nut==1)
//render()
hull(){
for(k = [0 : delta : 180])
translate([0,0,k*p/360])rotate([0,0,k])pieza_nut(diameter=diameter, p=p);
translate([0,0,180*p/360])rotate([0,0,180])pieza_nut(diameter=diameter, p=p);
}
else
//render()
hull(){
for(k = [0 : delta : 180])
translate([0,0,k*p/360])rotate([0,0,k])pieza(diameter=diameter, p=p);
translate([0,0,180*p/360])rotate([0,0,180])pieza(diameter=diameter, p=p);
}
}

module pieza(diameter, p)
{
r=diameter/2;
h=p*0.866;
pp=p/2;
pm=-p/2;
hh=r-h;
g=0.001;

rotate([90,0,0])
linear_extrude(height = g, center = true, convexity = 10){
polygon([
    [0,pp],[hh,pp],[r-h/8,p/16],[r-h/8,-p/16],[hh,pm],[0,pm]
    ], 
    [
    [0,1,2,3,4,5]
    ]);
}
}

module pieza_nut(diameter, p)
{
r=diameter/2;
h=p*0.866;
pp=p/2;
pm=-p/2;
hh=r-h;
g=0.001;
    
rotate([90,0,0])
linear_extrude(height = g, center = true, convexity = 10){
polygon([
    [0,pp],[hh,pp],[r,0],[hh,pm],[0,pm]
    ], 
    [
    [0,1,2,3,4]
    ]);
}
}
}



//Main Body
difference(){
  color("white")
  union(){
    rotate_extrude($fn=50)
        translate([0, 0])
            square([Diameter/2,Height-7]);
      translate([0,0,Height-7]){
        thread_for_screw(diameter=Diameter-3, length=5);
}
  }

   rotate_extrude($fn=50)
        translate([0, 2])
            square([(Diameter/2)-4.5,Height]);
    
    
    rotate_extrude($fn=50)
        translate([(Diameter/2)-2.5, -0.5])
          polygon([[0,0],[3,0],[3,3]]);
  
       if(Emoji_bottom==true){
            translate([0,0,1.5]){
            linear_extrude(0.6) offset(0.01)
                text(Bottom_special_character,size=Text_Size*5,halign="center",valign=        "center");
           
        }
    }
   
}
if(Emoji_bottom==true){
if (Text_and_Cirle=="Coloured"){
            translate([0,0,1.51]){
            linear_extrude(0.49)
            text(Bottom_special_character,size=Text_Size*5,halign="center",valign="center");
           
        }
    }
}

//Cap
translate([(Diameter)+2, 0]){
difference(){
  color("white")
  rotate_extrude($fn=50)
        translate([0, 0])
            square([Diameter/2,7]);
    
    rotate_extrude($fn=50)
        translate([(Diameter/2)-2.5, -0.5])
          polygon([[0,0],[3,0],[3,3]]);
    
    rotate_extrude($fn=50)
        translate([(Diameter/2)-3.4, 10.1])
          polygon([[0,0],[1,0],[0,-1]]);
          translate([0,0,2]){
        thread_for_nut(diameter=Diameter-3, length=6, usrclearance=0.1);
      }
      
 for(i =[0:n])
{
    phi = i*360/n;
    translate([(Diameter/2)*cos(phi),(Diameter/2)*sin(phi),0])
        cylinder(h=Height,r=0.6,$fn=10);
}
          if (Type=="Text"){
            rotate([0,180,0]){
            translate([0,0,-0.41]){
            linear_extrude(0.6) offset(0.01)
                text(Text,size=Text_Size,halign="center",valign=        "center");
            }
        }
        
    }

        if (Type=="Circle"){
            rotate_extrude($fn=50)
                translate([Diameter/3, -0.1])
                    square([Diameter/20,0.6]);
    }
        if (Type=="Emoji"){
            translate([0,0,-0.1]){
            linear_extrude(0.51) offset(0.01)
                text(Top_special_caracter,size=Text_Size*5,halign="center",valign="center");
            }
            
            
}
}
if (Text_and_Cirle=="Coloured"){
           if (Type=="Text"){
          rotate([0,180,0]){
          color("black")
           translate([0,0,-0.4]){
           linear_extrude(0.4)
        text(Text,size=Text_Size,halign="center",valign="center");
            }
        }
    }
    if (Type=="Circle"){
        color("black")
        rotate_extrude($fn=50)
                translate([(Diameter/3)+0.01, 0])
                    square([(Diameter/20)-0.02,0.49]);
    }
    if (Type=="Emoji"){
        color("black")
        translate([0,0,0]){
           linear_extrude(0.4)
            text(Top_special_caracter,size=Text_Size*5,halign="center",valign="center");
            }
        }
    }
}