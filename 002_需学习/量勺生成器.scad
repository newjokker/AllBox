include <BOSL2/std.scad>
// 参数化量勺生成器
/*[基本设置]*/
// 量勺的容量，单位为毫升（ml）
Spoon_Volume=20;
//量勺主体类型选择，半球形（Hemisphere）或者圆柱形（Cylindrical）
Spoon_type="C";//[H:半球形,C:圆柱形]
/*[高级设置]*/
//如果选择圆柱形（Cylindrical），可以输入量勺主体内直径，0表示自动计算（mm）。
Spoon_inner_diameter=0;
//手柄长度（mm）
Handle_length=75;
//手柄宽度（mm）
Handle_width=10;
//手柄悬挂孔直径（mm）
Handle_hole_diameter=6;
//字体大小(mm)
Text_size=10;
//手柄厚度（mm）
Handle_thickness=2.6;
//量勺主体壁厚（mm）
Spoon_wall_thickness=1;
/* [Hidden] */

// 调用量勺生成器并传入所需的容量（毫升）
measuring_spoon(Spoon_Volume); // 示例中生成一个15ml的量勺

module measuring_spoon(Volume_ml = 15) {
    Volume_mm_3=Volume_ml*1000;
    // 假设量勺形状为半球形，计算适合的半径
    // V = 4/3 * π * r^3 / 2, 我们解这个方程求r
    if(Spoon_type=="H")
    {
        r1 = pow((3 * Volume_mm_3) / (2 * PI),1/3); // 计算半径                
        spoon_maker(r=r1,h=0);
    }
    else
    if(Spoon_inner_diameter<=0)
    {
        r2 = pow((3 * Volume_mm_3) / (5 * PI),1/3); // 计算半径 
        spoon_maker(r=r2,h=r2);
    }
    else
    {
        r3=Spoon_inner_diameter/2;
        h3=Volume_mm_3/(PI*r3*r3)-2*r3/3;
        if(h3>=0)
        {spoon_maker(r=r3,h=h3);}
        else
        {Print_text("Spoon inner diameter的值太大了");}
        
    }
    
}
//spoon_maker();
//根据参数制作勺子r是圆柱内半径，h是圆柱高度
module spoon_maker(r=15,h=15)
{
    // 绘制量勺主体（半球）
    difference(){
    
        union(){
            up(h)
            difference(){
            sphere(r = r+Spoon_wall_thickness, $fn=100);
            down(r+Spoon_wall_thickness)cuboid([(r+Spoon_wall_thickness)*2+0.01,(r+Spoon_wall_thickness)*2+0.01,(r+Spoon_wall_thickness)*2]);
            }
            right(Handle_length/2+r)spoon_handle(r);
            if(h>0){up(h/2)cyl(l=h, r=r+Spoon_wall_thickness,$fn=100);}
        }
        up(h)sphere(r = r, $fn=100); // 使用高多边形数模拟平滑的球体
        if(h>0){up(h/2)cyl(l=h+0.01, r=r,$fn=100);}
    }
    
}
//spoon_handle();
module spoon_handle(r=5)
{
    difference(){
        up(Handle_thickness/2)
        difference(){
            union(){
                cuboid([Handle_length,Handle_width,Handle_thickness], rounding=Handle_width/2,edges=[FWD+RIGHT,BACK+RIGHT],$fn=24);
                left(Handle_length/2+r/2)cuboid([r+0.01,Handle_width,Handle_thickness], $fn=24);
                   }   
            right(Handle_length/2-Handle_width/2)cyl(l=Handle_thickness+0.01, d=Handle_hole_diameter,$fn=50);
            }
        yflip()volume_text(Spoon_Volume);
    }
}
//volume_text(Spoon_Volume);
//量勺文字函数
module volume_text(Volume_ml = 15) 
{
    text_temp=str_join([format_int(Volume_ml),"ml"]);   
    // 文字大小（mm）
    //Text_size = Text_size; 
    // 文字字体
    Text_font = "Noto Sans SC:style=Bold";// font
    //文字深度
    Text_thickness=0.6;
    up(Text_thickness/2)
    text3d(
    text=text_temp,
    font=Text_font, 
    size=Text_size*0.72,
    h=Text_thickness+0.01, 
    anchor=CENTER, 
    atype="ycenter");
}
//错误警告
//Print_text();
module Print_text(Text1="设计者忘记输入内容了") 
{
    Text_temp=Text1;   
    // 文字大小（mm）
    Text_size = 30; 
    // 文字字体
    Text_font = "Noto Sans SC:style=Bold";// font
    //文字深度
    Text_thickness=5;
    up(Text_thickness/2)
    text3d(
    text=Text_temp,
    font=Text_font, 
    size=Text_size*0.72,
    h=Text_thickness, 
    anchor=CENTER, 
    atype="ycenter");
}