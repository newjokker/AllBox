
$fn=50;


module boxRibTest(){
    boxRib(50, 40, 2, 5);
}

module roundedRectangle(w, h, r){
    minkowski(){
        square([w-2*r, h-2*r], center=true);
        circle(r);
    }
}

module boxRib(w, h, t, r){
    translate([0, 0, -t/2])
        linear_extrude(height = t)
            difference(){
                roundedRectangle(w+2*t, h+2*t, r);
                roundedRectangle(w, h, r);
            }        
}
    

boxRibTest();



