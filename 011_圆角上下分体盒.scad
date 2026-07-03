corner_radius_top    = 5; //[4:7]
corner_radius_bottom    = 2; //[2:2]
box_width          = 40;
box_length         = 30;
box_height      = 40;
box_wall_thickness = 2.2;
box_lid_height  = 10;
box_wall_border    = 8;
box_bot_thickness  = box_height - box_lid_height;
box_wall_half      = box_wall_thickness/2;
diff_gap           = 0.05;

$fn=60;

module xtorus(hr,rr)
{
  if (hr == rr) {
    sphere(r=hr);
  } else 
  if (hr > rr) {
    rotate_extrude()
      translate([hr-rr,0,0])
        circle(r=rr);
  } else {
    //////////////////////////
  }
}

module r_box_half(w,h,t,rcorner,rside)
{
  rrc = max(0.1,rcorner);
  rrs = max(0.1,rside);
  off_x = (w/2)-rrc;
  off_y = (h/2)-rrc;
  off_z = (t/2)-rrc;
  he = 0.2;
  off_e = -(t/2)+(he/2);
  hull()
  {
    translate([-off_x,-off_y,off_z])xtorus(hr=rrc,rr=rrs);
    translate([-off_x,+off_y,off_z])xtorus(hr=rrc,rr=rrs);
    translate([+off_x,+off_y,off_z])xtorus(hr=rrc,rr=rrs);
    translate([+off_x,-off_y,off_z])xtorus(hr=rrc,rr=rrs);
    translate([-off_x,-off_y,off_e])
      cylinder(r=rrc,h=he,center=true);
    translate([-off_x,+off_y,off_e])
      cylinder(r=rrc,h=he,center=true);
    translate([+off_x,+off_y,off_e])
      cylinder(r=rrc,h=he,center=true);
    translate([+off_x,-off_y,off_e])
      cylinder(r=rrc,h=he,center=true);
  }
}

module n_box_half(w,h,t,rside)
{
  rr = max(0.1,rside);
  off_x = (w/2)-rr;
  off_y = (h/2)-rr;
  hull()
  {
    translate([-off_x,-off_y,0])
      cylinder(r=rr,h=t,center=true);
    translate([-off_x,+off_y,0])
      cylinder(r=rr,h=t,center=true);
    translate([+off_x,+off_y,0])
      cylinder(r=rr,h=t,center=true);
    translate([+off_x,-off_y,0])
      cylinder(r=rr,h=t,center=true);
  }
}


module box_border(cc=0)
{
  difference()
  {
    n_box_half(w=box_width-(box_wall_half*2)+cc,
               h=box_length-(box_wall_half*2)+cc,
               t=box_wall_border,
               rside=corner_radius_top-box_wall_half);
    n_box_half(w=box_width-(box_wall_thickness*2)-cc,
               h=box_length-(box_wall_thickness*2)-cc,
               t=box_wall_border+diff_gap,
               rside=corner_radius_top-box_wall_thickness);
  }
}

module box_top()
{

  difference()
  {
    difference()
    {
      r_box_half(w=box_width, 
                 h=box_length,
                 t=box_lid_height, 
                 rcorner=corner_radius_top,
                 rside=corner_radius_top);
      translate([0,0,-(box_wall_thickness/2)-diff_gap])
        r_box_half(w=box_width-(box_wall_thickness*2), 
                   h=box_length-(box_wall_thickness*2),
                   t=box_lid_height-box_wall_thickness+diff_gap, 
                   rcorner=corner_radius_top-box_wall_thickness,
                   rside=corner_radius_top-box_wall_thickness);
    }
    translate([0,0,-box_lid_height/2])
      box_border(cc=diff_gap);
  }
}

module box_bottom()
{
  union()
  {
    difference()
    {
      r_box_half(w=box_width, 
                 h=box_length,
                 t=box_bot_thickness, 
                 rcorner=corner_radius_top,
                 rside=corner_radius_bottom);
    translate([0,0,-(box_wall_thickness/2)-diff_gap])
      r_box_half(w=box_width-(box_wall_thickness*2), 
                 h=box_length-(box_wall_thickness*2),
                 t=box_bot_thickness-box_wall_thickness+diff_gap, 
                 rcorner=corner_radius_top-box_wall_thickness,
                 rside=corner_radius_bottom-box_wall_thickness);
    }
    translate([0,0,-box_bot_thickness/2])
      box_border();
  }
}

rotate([180,0,0]) translate ([0, 0, -box_height/2+box_lid_height-box_wall_thickness])  box_bottom();
rotate([180,0,0]) translate ([0, box_length+10, -box_lid_height/2]) box_top();
