/*[SIZE 尺寸]*/

//宽度(mm)，内部宽度=宽度-9.6。Inner width = width - 9.6
width = 240; // [70:500]

//长度(mm)，内部长度=长度-13.8。Inner length = length - 13.8
length = 150;    // [60:500]

//高度(mm)，内部高度=高度-8。Inner height = height - 8
height = 50; // [45:240]

/*[TOP SURFACE 自定义顶面]*/
// 图标样式
logo_style = "default 默认"; //["default 默认", "emoji 表情"]

// 上一项选择“emoji”时生效，可以按键盘上的 Windows + “.” 来输入emoji表情。Effective when the previous selection is “emoji”, You can enter emojis by pressing Windows + "." 
emoji ="🎁";

// 顶面版式，目前自定义版式仅支持居中排版。Custom layout only supports centered layout now
top_surface_layout = "default 默认"; // ["default 默认", "custom 自定义"]

// 主标题文字，上一项选择“自定义”时有效。Effective when the previous selection is “custom”.
title_content = "TOOLBOX";

// 铭牌内容
tag_content = "三十而肥2017-Bilibili";

// 铭牌安装方式
tag_mounting_mode = "screw 螺丝";   //["screw 螺丝", "glue 胶水"]

/*[LINING 内衬]*/

//上部内衬高度比例(%)
upper_lining_height_percentage = 30;     //[0:100]

//下部内衬高度比例(%)
lower_lining_height_percentage = 30;     //[0:100]

//公差(mm)
tolerance = 0.2; //[0, 0.1, 0.2, 0.3, 0.4, 0.5]

/* [EXTRA] */
$fn = 50;

translate([0, -length / 2 - 10, 0]){ //底     

    difference(){
        union(){
            difference(){
                union(){    //主体
                    translate([0, 0, height * 2 / 3 / 2 - 2]){   //主体
                        minkowski(){
                            cylinder(4, 6, 10);
                            cube([width - 24, length - 24, height * 2 / 3 - 4], true); 
                        }
                    }
                    translate([0, 0, height * 2 / 3 - 0.4 - 4]){  //主体裙边
                        minkowski(){
                            union(){
                                translate([0 , 0, 2.4])
                                rotate([180, 0, 0])
                                cylinder(0.4, 11.6, 12);
                                cylinder(2, 10, 12);
                            }
                            cube([width - 24, length - 24, 4], true); 
                        }
                    }

                    {   //加强筋 
                        if(width < 120){             
                            //前          
                            translate([ 14.85, -length / 2 + 3, 0]) stiffener(height * 2 / 3); 
                            translate([-14.85, -length / 2 + 3, 0]) stiffener(height * 2 / 3);
                            //后
                            translate([ 20.54,  length / 2 - 3, 0]) mirror([0, 1, 0]) stiffener(height * 2 / 3);
                            translate([-20.54,  length / 2 - 3, 0]) mirror([0, 1, 0]) stiffener(height * 2 / 3);                        
                        }else{
                            //前
                                                translate([width * 0.25 + 14.85, -length / 2 + 3, 0]) stiffener(height * 2 / 3);
                                                translate([width * 0.25 - 14.85, -length / 2 + 3, 0]) stiffener(height * 2 / 3);                        
                            mirror([1, 0, 0])   translate([width * 0.25 + 14.85, -length / 2 + 3, 0]) stiffener(height * 2 / 3);
                            mirror([1, 0, 0])   translate([width * 0.25 - 14.85, -length / 2 + 3, 0]) stiffener(height * 2 / 3);
                            //后
                                                translate([width * 0.25 + 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 2 / 3);
                                                translate([width * 0.25 - 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 2 / 3);
                            mirror([1, 0, 0])   translate([width * 0.25 + 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 2 / 3);
                            mirror([1, 0, 0])   translate([width * 0.25 - 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 2 / 3);
                        }
                        
                        // 左右
                                                                translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 2 / 3);
                                            mirror([0, 1, 0])   translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 2 / 3);
                                            mirror([1, 0, 0])   translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 2 / 3);
                        mirror([0, 1, 0])   mirror([1, 0, 0])   translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 2 / 3);
                    }
                }

                if(width < 120){        //锁扣凹进去的部分
                    translate([-12.85, -length / 2, 0])
                    rotate([90, 0, 90])
                    linear_extrude(25.7)
                    polygon([[0, 0], [0, height * 2 / 3 + 0.01], [4.6, height * 2 / 3 +  + 0.01], [4.2, height * 2 / 3 - 0.4], [4.2, height * 2 / 3-4.4], [6.2, height * 2 / 3-6.4], [6.2, 2], [8.2, 0]]);
                }else{
                    translate([width * 0.25 - 12.85, -length / 2, 0])
                    rotate([90, 0, 90])
                    linear_extrude(25.7)
                    polygon([[0, 0], [0, height * 2 / 3 +  + 0.01], [4.6, height * 2 / 3 +  + 0.01], [4.2, height * 2 / 3 - 0.4], [4.2, height * 2 / 3-4.4], [6.2, height * 2 / 3-6.4], [6.2, 2], [8.2, 0]]);
                    mirror([1, 0, 0]){
                        translate([width * 0.25 -12.85,-length / 2, 0])
                        rotate([90, 0, 90])
                        linear_extrude(25.7)
                        polygon([[0, 0], [0, height * 2 / 3 + 0.01], [4.6, height * 2 / 3 +  + 0.01], [4.2, height * 2 / 3 - 0.4], [4.2, height * 2 / 3-4.4], [6.2, height * 2 / 3-6.4], [6.2, 2], [8.2, 0]]);
                    }
                }

                lining(height * 2 / 3 - 4 + 0.01, 0); //主体掏洞

            }

            if(width < 120){        //锁扣处凸出部分
                translate([-6.25, -length / 2 + 2.2, height * 2 / 3])
                rotate([90, 0, 90])
                linear_extrude(12.5)
                mirror([0, 1, 0])
                polygon(points=[[0, 0.4], [0.4, 0], [4, 0], [4, 11.72], [2, 9.72], [2, 7.72], [0, 5.72]]);

            }else{
                translate([width * 0.25 - 6.25, -length / 2 + 2.2, height * 2 / 3])
                rotate([90, 0, 90])
                linear_extrude(12.5)
                mirror([0, 1, 0])
                polygon(points=[[0, 0], [4, 0], [4, 11.72], [2, 9.72], [2, 7.72],[0, 5.72]]);
                mirror([1, 0, 0]){
                    translate([width * 0.25 - 6.25, -length/2 + 2.2,height * 2 / 3])
                    rotate([90,0,90])
                    linear_extrude(12.5)
                    mirror([0, 1, 0])
                    polygon(points=[[0, 0], [4, 0], [4, 11.72], [2, 9.72], [2, 7.72], [0, 5.72]]);
                }    
            }
        }
        
        if(width < 120){    //螺丝孔  

            translate([ - 3.88, -length / 2 + 2.19, height * 2 / 3 - 3.28])rotate([-90, 0, 0]) cylinder(6, 0.9, 0.9);
            translate([ + 3.88, -length / 2 + 2.19, height * 2 / 3 - 3.28])rotate([-90, 0, 0]) cylinder(6, 0.9, 0.9);

            translate([ - 4.59, length / 2, height * 2 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            translate([ + 4.59, length / 2, height * 2 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            
        }else{

            translate([width * 0.25 - 3.88, -length / 2 + 2.19, height * 2 / 3 - 3.28])rotate([-90, 0, 0]) cylinder(6, 0.9, 0.9);
            translate([width * 0.25 + 3.88, -length / 2 + 2.19, height * 2 / 3 - 3.28])rotate([-90, 0, 0]) cylinder(6, 0.9, 0.9);
            mirror([1, 0, 0]){        
                translate([width * 0.25 - 3.88, -length / 2 + 2.19, height * 2 / 3 - 3.28])rotate([-90, 0, 0]) cylinder(6, 0.9, 0.9);
                translate([width * 0.25 + 3.88, -length / 2 + 2.19, height * 2 / 3 - 3.28])rotate([-90, 0, 0]) cylinder(6, 0.9, 0.9);
            }

            translate([width * 0.25 - 4.59, length / 2, height * 2 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            translate([width * 0.25 + 4.59, length / 2, height * 2 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            mirror([1, 0, 0]){        
                translate([width * 0.25 - 4.59, length / 2, height * 2 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
                translate([width * 0.25 + 4.59, length / 2, height * 2 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            }
        }

        translate([0, 0, height * 2 / 3 + 0.01]) mirror([0, 0, 1]){  //接触面的凹槽
            translate([0, 0, 0]) difference(){

                groove();

                //去掉前面
                if(width < 120){
                    translate([0, - length / 2 + 2.4, 0.3]) cube([30.5, 1.4, 0.6], true);
                }else{
                    mirror([1, 0, 0]) translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5, 1.4, 0.6], true);
                    translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5, 1.4, 0.6], true);
                }

                //去掉后面
                translate([0, length / 2 - 2.4, 0.3]) cube([width - 24, 1.4, 0.6], true);
                translate([width / 2 - 12 + 0.199, length / 2 - 2.4, 0.3]) rotate([0, 0, 45]) cube([13.58, 13.58, 0.6], true);
                mirror([1, 0, 0]) translate([width / 2 - 12 + 0.199, length / 2 - 2.4, 0.3]) rotate([0, 0, 45]) cube([13.58, 13.58, 0.6], true);

            } 
            
            translate([0, 4.5, 0]) intersection(){       //前面缺口处的一段
                groove();
                union(){
                    if(width < 120){
                        translate([0, - length / 2 + 2.4, 0.3]) cube([30.5 + 0.401, 1.4, 0.6], true);
                    }else{
                        mirror([1, 0, 0]) translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5 + 0.401, 1.4, 0.6], true);
                        translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5 + 0.401, 1.4, 0.6], true);
                    }

                }
            } 
        }
    }
}

mirror([0, 1, 0]) translate([0, -length / 2 - 10, 0]) { //盖

    difference(){
        union(){
            difference(){
                union(){    //主体
                    translate([0, 0, height * 1 / 3 / 2 - 2]){   //主体
                        minkowski(){
                            cylinder(4, 6, 10);
                            cube([width - 24, length - 24, height * 1 / 3 - 4], true); 
                        }
                    }

                    translate([0, 0, height * 1 / 3 - 0.4 - 4]){  //主体裙边
                        minkowski(){
                            union(){
                                translate([0 , 0, 2.4])
                                rotate([180, 0, 0])
                                cylinder(0.4, 11.6, 12);
                                cylinder(2, 10, 12);
                            }
                            cube([width - 24, length - 24, 4], true); 
                        }
                    }
                
                    {   //加强筋 
                        if(width < 120){             
                            //前          
                            translate([ 14.85, -length / 2 + 3, 0]) stiffener(height * 1 / 3); 
                            translate([-14.85, -length / 2 + 3, 0]) stiffener(height * 1 / 3);
                            //后
                            translate([ 20.54,  length / 2 - 3, 0]) mirror([0, 1, 0]) stiffener(height * 1 / 3);
                            translate([-20.54,  length / 2 - 3, 0]) mirror([0, 1, 0]) stiffener(height * 1 / 3);                        
                        }else{
                            //前
                                                translate([width * 0.25 + 14.85, -length / 2 + 3, 0]) stiffener(height * 1 / 3);
                                                translate([width * 0.25 - 14.85, -length / 2 + 3, 0]) stiffener(height * 1 / 3);                        
                            mirror([1, 0, 0])   translate([width * 0.25 + 14.85, -length / 2 + 3, 0]) stiffener(height * 1 / 3);
                            mirror([1, 0, 0])   translate([width * 0.25 - 14.85, -length / 2 + 3, 0]) stiffener(height * 1 / 3);
                            //后
                                                translate([width * 0.25 + 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 1 / 3);
                                                translate([width * 0.25 - 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 1 / 3);
                            mirror([1, 0, 0])   translate([width * 0.25 + 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 1 / 3);
                            mirror([1, 0, 0])   translate([width * 0.25 - 20.54, length / 2 - 3,0]) mirror([0, 1, 0]) stiffener(height * 1 / 3);
                        }
                        
                        // 左右
                                                                translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 1 / 3);
                                            mirror([0, 1, 0])   translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 1 / 3);
                                            mirror([1, 0, 0])   translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 1 / 3);
                        mirror([0, 1, 0])   mirror([1, 0, 0])   translate([ width / 2 - 3, length / 6, 0]) rotate([0, 0, 90]) stiffener(height * 1 / 3);
                    }
                }

                if(width < 120){        //锁扣凹进去的部分            
                    translate([-12.85, -length/2, 0])
                    rotate([90,0,90])
                    linear_extrude(25.7)
                    polygon([[0, 0], [0, height * 1 / 3 + 0.01], [4.6, height * 1 / 3 + 0.01], [4.2, height * 1 / 3 - 0.4], [4.2, height * 1 / 3 - 4.4], [6.2, height * 1 / 3 - 6.4], [6.2, 2], [8.2, 0]]);
                }else{
                    translate([width * 0.25 -12.85,-length/2,0])
                    rotate([90,0,90])
                    linear_extrude(25.7)
                    polygon([[0, 0], [0, height * 1 / 3 + 0.01], [4.6, height * 1 / 3 + 0.01], [4.2, height * 1 / 3 - 0.4], [4.2, height * 1 / 3 - 4.4], [6.2, height * 1 / 3 - 6.4], [6.2, 2], [8.2, 0]]);
                    mirror([1, 0, 0]){
                        translate([width * 0.25 -12.85,-length/2,0])
                        rotate([90,0,90])
                        linear_extrude(25.7)
                        polygon([[0, 0], [0, height * 1 / 3 + 0.01], [4.6, height * 1 / 3 + 0.01], [4.2, height * 1 / 3 - 0.4], [4.2, height * 1 / 3-4.4], [6.2, height * 1 / 3-6.4], [6.2, 2], [8.2, 0]]);
                    }
                }

                lining(height * 1 / 3 - 4 + 0.01, 0); //主体掏洞
            }

            if(width < 120){        //锁扣处凸出部分

                translate([-9.45, -length / 2 + 4.2, height * 1 / 3]) difference(){
                    rotate([90, 0, 90]) linear_extrude(18.9)
                    mirror([0, 1, 0]) polygon([[0, 0.4], [0.4, 0], [2, 0], [2, 8.52], [0, 6.52]]);
                    translate([   0, 1, -8.52]) rotate([0, 45, 0]) cube([2 * sqrt(2), 2, 2 * sqrt(2)], true);
                    translate([18.9, 1, -8.52]) rotate([0, 45, 0]) cube([2 * sqrt(2), 2, 2 * sqrt(2)], true);
                }

            }else{
                translate([width * 0.25 - 9.45, -length / 2 + 4.2, height * 1 / 3]) difference(){
                    rotate([90, 0, 90]) linear_extrude(18.9)
                    mirror([0, 1, 0]) polygon([[0, 0.4], [0.4, 0], [2, 0], [2, 8.52], [0, 6.52]]);
                    translate([   0, 1, -8.52]) rotate([0, 45, 0]) cube([2 * sqrt(2), 2, 2 * sqrt(2)], true);
                    translate([18.9, 1, -8.52]) rotate([0, 45, 0]) cube([2 * sqrt(2), 2, 2 * sqrt(2)], true);
                }
                mirror([1, 0, 0]){
                    translate([width * 0.25 - 9.45, -length / 2 + 4.2, height * 1 / 3]) difference(){
                        rotate([90, 0, 90]) linear_extrude(18.9)
                        mirror([0, 1, 0]) polygon([[0, 0.4], [0.4, 0], [2, 0], [2, 8.52], [0, 6.52]]);
                        translate([   0, 1, -8.52]) rotate([0, 45, 0]) cube([2 * sqrt(2), 2, 2 * sqrt(2)], true);
                        translate([18.9, 1, -8.52]) rotate([0, 45, 0]) cube([2 * sqrt(2), 2, 2 * sqrt(2)], true);
                    }
                }    
            }

            translate([0, 0, height * 1 / 3 - 0.1]) {  //接触面的凸起
                difference(){

                    groove();

                    //去掉前面
                    if(width < 120){
                        translate([0, - length / 2 + 2.4, 0.3]) cube([30.5, 1.4, 0.6], true);
                    }else{
                        mirror([1, 0, 0]) translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5, 1.4, 0.6], true);
                        translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5, 1.4, 0.6], true);
                    }

                    //去掉后面
                    translate([0, length / 2 - 2.4, 0.3]) cube([width - 24, 1.4, 0.6], true);
                    translate([width / 2 - 12 + 0.199, length / 2 - 2.4, 0.3]) rotate([0, 0, 45]) cube([13.58, 13.58, 0.6], true);
                    mirror([1, 0, 0]) translate([width / 2 - 12 + 0.199, length / 2 - 2.4, 0.3]) rotate([0, 0, 45]) cube([13.58, 13.58, 0.6], true);

                } 
                
                translate([0, 4.5, 0]) intersection(){       //前面缺口处的一段
                    groove();
                    union(){
                        if(width < 120){
                            translate([0, - length / 2 + 2.4, 0.3]) cube([30.5 + 0.401, 1.4, 0.6], true);
                        }else{
                            mirror([1, 0, 0]) translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5 + 0.401, 1.4, 0.6], true);
                            translate([width * 0.25, - length / 2 + 2.4, 0.3]) cube([30.5 + 0.401, 1.4, 0.6], true);
                        }

                    }
                } 
            }            
        }
        
        if(width < 120){    //螺丝孔  

            translate([ - 3.88, -length / 2 + 3.5, height * 1 / 3 - 3.81])rotate([-90, 0, 0]) cylinder(5, 0.9, 0.9);
            translate([ + 3.88, -length / 2 + 3.5, height * 1 / 3 - 3.81])rotate([-90, 0, 0]) cylinder(5, 0.9, 0.9);

            translate([ - 4.59, length / 2, height * 1 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            translate([ + 4.59, length / 2, height * 1 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            
        }else{

            translate([width * 0.25 - 3.88, -length / 2 + 3.5, height * 1 / 3 - 3.81])rotate([-90, 0, 0]) cylinder(5, 0.9, 0.9);
            translate([width * 0.25 + 3.88, -length / 2 + 3.5, height * 1 / 3 - 3.81])rotate([-90, 0, 0]) cylinder(5, 0.9, 0.9);
            mirror([1, 0, 0]){        
                translate([width * 0.25 - 3.88, -length / 2 + 3.5, height * 1 / 3 - 3.81])rotate([-90, 0, 0]) cylinder(5, 0.9, 0.9);
                translate([width * 0.25 + 3.88, -length / 2 + 3.5, height * 1 / 3 - 3.81])rotate([-90, 0, 0]) cylinder(5, 0.9, 0.9);
            }

            translate([width * 0.25 - 4.59, length / 2, height * 1 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            translate([width * 0.25 + 4.59, length / 2, height * 1 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            mirror([1, 0, 0]){        
                translate([width * 0.25 - 4.59, length / 2, height * 1 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
                translate([width * 0.25 + 4.59, length / 2, height * 1 / 3 - 2.98])rotate([90, 0, 0]) cylinder(4.5, 0.9, 0.9);
            }
        }

        top_surface(preview = false);   //顶面元素
    }
}

{ // 内衬
    translate([width + 30, -length / 2 - 10, 0]) 
    lining(height * 2 / 3 * lower_lining_height_percentage / 100 - 4, tolerance);  

    mirror([0, 1, 0]) 
    translate([width + 30, -length / 2 - 10, 0]) 
    lining(height * 1 / 3 * upper_lining_height_percentage / 100 - 4, tolerance);
}


translate([0, length + 10 + 30, 0]) { // tag
    if(top_surface_layout == "default 默认" && width >= 120){
        // 算法在下面的module top_surface(preview)里
        h = (length - 12) * 2 / 3 - 19.94;
        w = ((width - 12) * 2 / 3 - 19.94) / (1 + 1 / 6.44);
        title_width  = (w / h < 6.44) ? w : h * 6.44;
        title_height = (w / h < 6.44) ? w / 6.44 : h;
        char_space = (title_width - 2.83) / 9 - 0.08;
        tag_width = (title_width > 100) ? 80 : title_width - 0.6;

        tag(tag_width);

    }else{
        h = ((length - 12) * 2 / 3 - 14) / 4;
        w = (width - 12) * 2 / 3;        
        title_width  = (w / h < 6.44) ? w : h * 6.44;
        title_height = (w / h < 6.44) ? w / 6.44 : h;
        tag_width = (title_width > 80) ? 80 : title_width - 0.6;

        tag(tag_width);
        echo(str("1 = ", tag_width));
    }
}

{   // 预览
    translate([-width - 30, length / 2 + 10, 0]) top_surface(preview = true);
    translate([-width - 30, length / 2 + 10, 0]) {  //预览边框
        difference(){       
            minkowski(){
                translate([0, 0, 0.1])
                cylinder(0.2, 6.4, 6.4);
                cube([width - 24, length - 24, 0.2], true); 
            }
            minkowski(){
                cylinder(0.3, 6, 6);
                cube([width - 24, length - 24, 0.3], true); 
            }
        }
        translate([-width / 2 + 6, length / 2 - 3 + 3, 0]) linear_extrude(0.01) text("预览 Preview", 5, "HarmonyOS Sans SC:style=Black", halign = "left", valign = "bottom");
        translate([-width / 2 + 6, length / 2 - 4.5, 0]) linear_extrude(0.01) text("无需打印 don't print", 2.5, "HarmonyOS Sans SC:style=Black", halign = "left", valign = "bottom");
    } 
}

// 顶面文字和logo
// openscad导出的模型默认是一个整体，即无论多少模型都是布尔相加后再导出，
// 所以没法办在物体中嵌入文字，只能挖一个0.01的槽来创造一个能给切片软件上色的面
module top_surface(preview) { 
    
    //translate([0, 1, 0])

    if(top_surface_layout == "default 默认" && width >= 120){
        // title_width / title_height = 6.44
        /*
        h + 8.03 + 11.91 = length * 2 / 3
        w + (w / 6.44 + 8.03 + 11.91) = width * 2 / 3
        */
        h = (length - 12) * 2 / 3 - 19.94;
        w = ((width - 12) * 2 / 3 - 19.94) / (1 + 1 / 6.44);

        title_width  = (w / h < 6.44) ? w : h * 6.44;
        title_height = (w / h < 6.44) ? w / 6.44 : h;
        char_space = (title_width - 2.83) / 9 - 0.08;
        tag_width = (title_width > 100) ? 80 : title_width - 0.6;

        // 字："TOOLBOX"
        translate([(title_height + 19.94) / 2, 1.94, 0]) linear_extrude(0.01) 
        text("TOOLBOX", title_height, "Rubik:style=Bold", halign = "center", valign = "center");

        // 字："3DPRINTING"
        // text函数中的spacing似乎有bug，总是间距不同，不知道是不是我用法不对，这里只能列数组了
        // linear_extrude(0.4) text("3DPRINTING", 4.5, "norwester:style=Regular", halign = "center", valign = "center", spacing = 3);
        chars = ["3", "D", "P", "R", "I", "N", "T", "I", "N", "G"];
        translate([2.1 + (title_height + 19.94) / 2, title_height / 2 + 3 + 1.94, 0]) linear_extrude(0.01) for (a = [0:10]) {
            translate([- title_width / 2 + a * char_space, 0, 0]) 
            text(chars[a], 4.5, "norwester:style=Regular", halign = "center", valign = "bottom");
        }

        // 铭牌
        translate([(title_height + 19.94) / 2 - title_width / 2  + tag_width / 2 + 0.3, - title_height / 2 - 7.3 + 1.94, 0])
        if(preview == false){
            hull() {
                translate([ tag_width / 2 - 4, 0, 0]) cylinder(1.8, 4.3, 4.3);
                translate([-tag_width / 2 + 4, 0, 0]) cylinder(1.8, 4.3, 4.3);
            }
            if(tag_mounting_mode == "screw 螺丝"){
                translate([ tag_width / 2 - 4, 0, 0]) cylinder(4.1, 1, 1);
                translate([-tag_width / 2 + 4, 0, 0]) cylinder(4.1, 1, 1);
            }

        }else{
            TagPreview(tag_width);
        }

        // logo
        translate([-title_width / 2 - (title_height + 19.94) * 0.05, 0, 0]) scale([0.9 * (title_height + 19.94), 0.9 *(title_height + 19.94), 1])
        logo();


    }else{

        //w / h = 6.44
        /*
        h + 3 * h + 8 + 3 + 3 = length * 2 / 3  // 栅格 = 3
        w = width * 2 / 3
        */        
        h = ((length - 12) * 2 / 3 - 14) / 4;
        w = (width - 12) * 2 / 3;
        
        title_width  = (w / h < 6.44) ? w : h * 6.44;
        title_height = (w / h < 6.44) ? w / 6.44 : h;
        tag_width = (title_width > 80) ? 80 : title_width - 0.6;
        echo(str("2 = ", tag_width));

        translate([0, (4 * title_height + 12) / 2 - (title_height / 2 + 3 + 3 * title_height) + 2, 0]){

            // logo
            translate([0, 1.5 * title_height + title_height / 2 + title_height * 0.35, 0]) 
            scale([3 * title_height, 3 * title_height, 1]) 
            logo();

            if (top_surface_layout == "custom 自定义"){

                translate([0, 0, 0]) 
                linear_extrude(0.01) 
                text(title_content, title_height, "HarmonyOS Sans SC:style=Black", halign = "center", valign = "center");

            }else{

                translate([0, 0, 0]) 
                linear_extrude(0.01) 
                text("TOOLBOX", title_height, "Rubik:style=Bold", halign = "center", valign = "center");

            }

            // 铭牌
            translate([0, -title_height / 2 - 4 - title_height * 0.35, 0])
            if(preview == false){
                hull() {    
                    translate([ tag_width / 2 - 4, 0, 0]) cylinder(1.8, 4.3, 4.3);
                    translate([-tag_width / 2 + 4, 0, 0]) cylinder(1.8, 4.3, 4.3);
                }
                if(tag_mounting_mode == "screw 螺丝"){
                    translate([ tag_width / 2 - 4, 0, 0]) cylinder(4.1, 1, 1);
                    translate([-tag_width / 2 + 4, 0, 0]) cylinder(4.1, 1, 1);
                }
            }else{
                TagPreview(tag_width);
            }
        }
    } 

}

module logo(){ 
    if(logo_style == "emoji 表情"){        
        scale([0.65, 0.65, 1]) linear_extrude(0.01) text(emoji, 1, "noto emoji", halign = "center", valign = "center");
    }else{
        scale([0.01, 0.01, 1]){

            intersection(){
                union(){
                    linear_extrude(0.01) scale(10) polygon([[4.6565,-0.4611],[0.7990,-0.4611],[2.3824,-4.1497],[1.4864,-4.4005],[0,-0.9377],[-1.4031,-4.2062],[-2.3750,-4.1324],[-0.5230,0.1819],[-0.1035,0.4611],[4.4166,0.4611]]);
                    translate([-0.9922, 0, 0]) cylinder(0.01, 4.62, 4.62);
                }
                translate([0, 0, -0.1]) cylinder(0.5, 40.8, 40.8);
            }

            difference(){
                cylinder(0.02, 50, 50);
                translate([0, 0, -0.1]) cylinder(0.3, 40.8, 40.8);
            }

        }
    }
}

module tag(tag_width){
    difference(){
        hull() {    
            translate([- tag_width / 2 + 4, 0, 0]) cylinder(1.6, 4, 4);
            translate([  tag_width / 2 - 4, 0, 0]) cylinder(1.6, 4, 4);
        }

        hull() {    
            translate([- tag_width / 2 + 4, 0, 1.4]) cylinder(0.21, 3.2, 3.2);
            translate([  tag_width / 2 - 4, 0, 1.4]) cylinder(0.21, 3.2, 3.2);
        }

        if(tag_mounting_mode == "screw 螺丝"){
            translate([- tag_width / 2 + 4, 0,  0.4]) cylinder(1.2, 1.2, 2);
            translate([- tag_width / 2 + 4, 0, -0.1]) cylinder(2, 1.2, 1.2);

            translate([  tag_width / 2 - 4, 0,  0.4]) cylinder(1.2, 1.2, 2);
            translate([  tag_width / 2 - 4, 0, -0.1]) cylinder(2, 1.2, 1.2);
        }

    }
    translate([0, 0, 1.4]) linear_extrude(0.2) text(tag_content, 4.5, "HarmonyOS Sans SC:style=Black", halign = "center", valign = "center");
}

module TagPreview(tag_width){
    difference(){

        hull() {    
            translate([- tag_width / 2 + 4, 0, 0]) cylinder(0.01, 4, 4);
            translate([  tag_width / 2 - 4, 0, 0]) cylinder(0.01, 4, 4);
        }

        hull() {    
            translate([- tag_width / 2 + 4, 0, -0.1]) cylinder(0.21, 3.2, 3.2);
            translate([  tag_width / 2 - 4, 0, -0.1]) cylinder(0.21, 3.2, 3.2);
        }

     }

    if(tag_mounting_mode == "screw 螺丝"){
        difference(){
            union(){
                translate([- tag_width / 2 + 4, 0,  0.4]) cylinder(0.01, 2, 2);
                translate([  tag_width / 2 - 4, 0,  0.4]) cylinder(0.01, 2, 2);
            }

            union(){
                translate([- tag_width / 2 + 4, 0,  0.4]) cube([2, 0.4, 0.2], true);
                translate([- tag_width / 2 + 4, 0,  0.4]) cube([0.4, 2, 0.2], true);
                translate([  tag_width / 2 - 4, 0,  0.4]) cube([2, 0.4, 0.2], true);
                translate([  tag_width / 2 - 4, 0,  0.4]) cube([0.4, 2, 0.2], true);
            }
        }
    }
    translate([0, 0, 0]) linear_extrude(0.01) text(tag_content, 4.5, "HarmonyOS Sans SC:style=Black", halign = "center", valign = "center");
}
//三十而肥2017@Bilibili.com

module groove(){    //槽

    difference(){

        translate([0, 0, 0.1]) minkowski(){
            cylinder(0.4, 10.3, 9.9);
            cube([width - 24, length - 24, 0.2],true);
        }

        translate([0, 0, 0.3]) minkowski(){
            cylinder(0.4, 8.95, 9.35);
            cube([width - 24, length - 24, 0.2],true);
        }

        translate([0, 0, 0]) minkowski(){
            cylinder(0.2, 8.95, 8.95);
            cube([width - 24, length - 24, 0.1],true);
        }

    }
}

module stiffener(stiffener_height){   //加强筋
    translate([-2, -3, 0])
    difference(){
        cube([4, 6, stiffener_height - 0.4]); 

        translate([-0.01, 0, -(6 * sqrt(2) - 4)])
        rotate([45, 0, 0])
        cube([4.02, 6, 6]); 

    }
}

module lining(lining_height, lining_tolerance){         //内衬
    h = lining_height < 2.01 ? 2.01 : lining_height;
    difference(){
        translate([0, 0, h / 2 + 3])   //主体
        minkowski(){
            cylinder(2, 5.2, 7.2);
            cube([width - 24 - lining_tolerance * 2, length - 24 - lining_tolerance * 2, h - 2], true); 
        }

        if(width < 120){        //凸出部分和螺丝孔
            translate([-12.85 - 4.8 - lining_tolerance, -length / 2 + 4.8 + lining_tolerance, 0])              cube([25.7 + 9.6 + 2 * lining_tolerance, 4.2 + lining_tolerance, height * 2 / 3]);
        }else{
            translate([width * 0.25 -12.85 - 4.8 - lining_tolerance, -length / 2 + 4.8 + lining_tolerance, 0]) cube([25.7 + 9.6 + 2 * lining_tolerance, 4.2 + lining_tolerance, height * 2 / 3]);
            mirror([1, 0, 0])
            translate([width * 0.25 -12.85 - 4.8 - lining_tolerance, -length / 2 + 4.8 + lining_tolerance, 0]) cube([25.7 + 9.6 + 2 * lining_tolerance, 4.2 + lining_tolerance, height * 2 / 3]);                            
        }
    }

}
