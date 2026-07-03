// 陈优秀重庆 v1.2版本
// 陈优秀重庆 模型设计
// 陈优秀重庆 代码编译 2024/11/11/2:29
// 陈优秀重庆 纯Openscad小白，现学现编历时间3天，堆出来的屎山代码，哈哈哈。

/* [盒子尺寸参数] */
//盒子内空间长 单位:mm 
lt = 120;//[72:234]
//盒子内空间宽 单位:mm 
wt = 60;//[20:220]
//盒子内空间高 底盒部分 单位:mm 
hdt = 32;//[25:240]
//盒子内空间高 盖子部分 单位:mm 
hut = 18;//[15:240]
//盒子壁厚 单位:mm  不得超过壁厚的0.7倍
bt = 5;//[4:8]
//立边圆角半径 单位:mm 必须大于壁厚 且 大于dlt的1.5倍
brt = 10;//[8:25]
//盒子的底厚 盖厚 单位:mm。 
dt = bt/2;
//盒子的上下壳倒角 单位:mm。 
dlt = 4;//[2:5]
/* [加强筋 / 锁扣 的间距] */
//侧面加强筋的距离 单位:mm
jqt = 30;//[10:210]
//正面锁扣的距离 单位:mm
kjqt = 60;//[32:194]

/* [颜色调整] */
//底盒的颜色
boxColor = "#696AAD"; // color
//锁扣的颜色
skColor = "#696AAD"; // color
//盖子的颜色
gaiColor = "#D2D2D2"; // color


// 生成 底盒掏空  部分
module dihetk(
    zt = -lt/2-bt+brt,  // 左边的 X 坐标
    yt = lt/2+bt-brt,  // 右边的 X 坐标
    qt = 11+brt,  // 前面的 Y 坐标
    ht = 11+bt*2+wt-brt,  // 后面的 Y 坐标
    r1 = brt-bt/2-dlt-bt/2*0.41,   // 底部梯形的 下圆 半径
    r2 = brt-bt,  // 底部梯形的 上圆 半径
    r3 = brt-bt,   // 腰部梯形的 下圆 半径
    r4 = brt-bt+0.4,  // 腰部梯形的 上圆 半径
    r5 = brt-bt/2-0.4,   // 顶部梯形的 下圆 半径
    r6 = brt-bt/2+0.6,  // 顶部梯形的 上圆 半径
    dh1 = dt,  // 底部梯形的 底 Z 坐标
    dh2 = dlt+bt/2*0.41,  // 底部梯形的 顶 Z 坐标
    dh3 = hdt+dt-1.4,  // 腰部梯形的 底 Z 坐标
    dh4 = hdt+dt-1,  // 顶部梯形的 底 Z 坐标
    h1 = dlt+bt/2*0.41-dt,  // 底部梯形的 高度
    h2 = hdt+dt-dlt-bt/2*0.41-1.4,  // 中间圆柱的 高度
    h3 = 0.4,  // 腰部梯形的 高度
    h4 = 1,  // 顶部梯形的 高度
) {
  color(boxColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数 底部梯形+腰部柱体
        translate ([zt, qt, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, qt, dh2]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([zt, ht, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh2])
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt,qt, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt,qt, dh2]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt, ht, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh2])  
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
    }
    hull() {  //包裹生成 函数 中间倒角
        translate ([zt, qt, dh3]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh3]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt,qt, dh3]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh3]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
    }
    hull() {  //包裹生成 函数 顶部梯形
        translate ([zt, qt, dh4]) 
          cylinder(h = h4, r1 = r5, r2 = r6, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh4]) 
          cylinder(h = h4, r1 = r5, r2 = r6, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt,qt, dh4]) 
          cylinder(h = h4, r1 = r5, r2 = r6, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh4]) 
          cylinder(h = h4, r1 = r5, r2 = r6, $fn = 32);  // 创建 倒 梯形圆锥
    }
  }
}

// 生成 底盒  部分
module dihest_1(
    zt = -lt/2-bt+brt,
    yt = lt/2+bt-brt,
    qt = 11+brt,
    ht = 11+bt*2+wt-brt,
    r1 = brt-bt/2-dlt, 
    r2 = brt-bt/2,
    r3 = brt-bt/2, 
    r4 = brt,
    r5 = brt-0.4,
    dh1 = hdt+dt-bt,
    dh2 = hdt+dt-bt/2,
    dh3 = hdt+dt-0.4,
    h1 = dlt,
    h2 = hdt+dt-bt-dlt,
    h3 = bt/2,
    h4 = bt/2-0.4,
    h5 = 0.4,
) {
  color(boxColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数 底部梯形+中间柱体
        translate ([zt, qt, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, qt, dlt]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([zt, ht, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dlt])
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt,qt, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt,qt, dlt]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt, ht, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dlt])  
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
    }
    hull() {  //包裹生成 函数 腰部梯形+顶部柱体+顶部倒角
        translate ([zt, qt, dh1]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, qt, dh2]) 
          cylinder(h = h4, r = r4, $fn = 32);  // 创建 圆柱
        translate ([zt, qt, dh3]) 
          cylinder(h = h5, r1 = r4, r2 = r5, $fn = 32);  // 创建 顶部倒角 梯形圆锥
        translate ([zt, ht, dh1]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh2]) 
          cylinder(h = h4, r = r4, $fn = 32);  // 创建 圆柱
        translate ([zt, ht, dh3]) 
          cylinder(h = h5, r1 = r4, r2 = r5, $fn = 32);  // 创建 顶部倒角 梯形圆锥
        translate ([yt, ht, dh1]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh2]) 
          cylinder(h = h4, r = r4, $fn = 32);  // 创建 圆柱
        translate ([yt, ht, dh3]) 
          cylinder(h = h5, r1 = r4, r2 = r5, $fn = 32);  // 创建 顶部倒角 梯形圆锥
        translate ([yt, qt, dh1]) 
          cylinder(h = h3, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, qt, dh2]) 
          cylinder(h = h4, r = r4, $fn = 32);  // 创建 圆柱
        translate ([yt, qt, dh3]) 
          cylinder(h = h5, r1 = r4, r2 = r5, $fn = 32);  // 创建 顶部倒角 梯形圆锥
    }
  }
}

// 对 底盒部分 进行掏空
  difference() {
    dihest_1();
    dihetk();
  }

// 生成 左右侧加强筋 前面 部分
module dihest_2(
    zt1 = -lt/2-bt+dlt+0.6,
    yt1 = lt/2+bt-dlt-0.6,
    qt = 11.6+bt+wt/2-jqt/2, 
    ht = 13.6+bt+wt/2-jqt/2,
    zt2 = -lt/2-bt+0.6,
    yt2 = lt/2+bt-0.6,
    r1 = 0.6, 
    dh1 = 0.6,
    dh2 = dlt,
    dh3 = hdt+dt-1,
) {
  color(boxColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数
        translate ([zt1, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左前 球体
        translate ([zt1, ht, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左后 球体
        translate ([yt1, ht, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右后 球体
        translate ([yt1, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右前 球体
        translate ([zt2, qt, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中左前 球体
        translate ([zt2, ht, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中左后 球体
        translate ([yt2, ht, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中右后 球体
        translate ([yt2, qt, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中右前 球体
        translate ([zt2, qt, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左前 球体
        translate ([zt2, ht, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左后 球体
        translate ([yt2, ht, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右后 球体
        translate ([yt2, qt, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右前 球体
    }
  }
}

// 对 左右加强筋 进行掏空
  difference() {
    dihest_2();
    dihetk();
  }

// 镜像 左右侧加强筋前面部分 生成后面部分 并掏空
  translate([0, wt+bt*2+11*2, 0])  //偏移倒 底盒模型的 前后中点
    mirror([0, 1, 0]) {   // 沿X轴镜像运算模型
      difference() {
        dihest_2();
        dihetk();
      }
    }

// 命名 前后加强筋 左边部分
module dihest_3() {
// 生成 后加强筋 左侧 右边部分 的点阵部分
module dihest_3_1(
    zt = -kjqt/2+10.6,  // 点阵左X坐标
    yt = -kjqt/2+14.4,  // 点阵右X坐标
    qt = 6.6+bt+wt,  // 点阵前Y坐标
    ht1 = 10.4+bt*2+wt-dlt,  // 点阵底部倒角 下顶点 Y坐标
    ht2 = 10.4+bt*2+wt,  // 点阵底部倒角 上顶点 Y坐标
    ht3 = 17.4+bt*2+wt,  // 点阵顶部 后  Y坐标
    ht4 = 14.5+bt*2+wt,  // 点阵顶部 下陷 Y坐标
    ht5 = 11+bt*2+wt,  // 点阵顶部 中 Y坐标
    r1 = 0.6, 
    dh1 = 0.6,  // 点阵底部倒角 下顶点 Z坐标
    dh2 = dlt,  // 点阵底部倒角 上顶点 Z坐标
    dh3 = hdt+dt-3.5,  // 点阵腰部 Z坐标
    dh4 = hdt+dt-0.6,  // 点阵顶部 前 Z坐标
    dh5 = hdt+dt-2.9,  // 点阵顶部 下陷 Z坐标
    dh6 = hdt+dt,  // 点阵顶部 后 Z坐标
) {
  color(boxColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数
        translate ([zt, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左前 球体
        translate ([yt, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右前 球体
        translate ([zt, ht1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底倒角左底 球体
        translate ([yt, ht1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底倒角右底 球体
        translate ([zt, ht2, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 底倒角左上 球体
        translate ([yt, ht2, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 底倒角右上 球体
        translate ([zt, ht3, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 腰部左 球体
        translate ([yt, ht3, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 腰部右 球体
        translate ([zt, ht3, dh6]) 
          sphere(r=r1, $fn = 8);  // 创建 顶部左后 球体
        translate ([yt, ht3, dh6]) 
          sphere(r=r1, $fn = 8);  // 创建 顶部右后 球体
        translate ([zt, ht4, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 顶部下陷点左 球体
        translate ([yt, ht4, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 顶部下陷点右 球体
    }
    hull() {  //包裹生成 函数
        translate ([zt, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左前 球体
        translate ([yt, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右前 球体
        translate ([zt, qt, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左前 球体
        translate ([yt, qt, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右前 球体
        translate ([zt, ht5, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左中 球体
        translate ([yt, ht5, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右中 球体
        translate ([zt, ht4, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 顶部下陷点左 球体
        translate ([yt, ht4, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 顶部下陷点右 球体
    }
  }
}
// 对 后加强筋 左侧 右边部分 的点阵部分 进行掏空
  difference() {
    dihest_3_1();
    dihetk();
  }

// 镜像 后加强筋实体 的左侧 左边部分 并掏空
  translate([-kjqt, 0, 0])  // 镜像后实体的偏移量
    mirror([1, 0, 0]) {   // 沿y轴镜像运算模型
      difference() {
        dihest_3_1();
        dihetk();
      }
    }

// 生成 后加强筋 左侧 右边部分 的圆柱部分
module dihest_3_2(
    xt = -kjqt/2+10.6,  // 圆柱基点的 X坐标
    yt = 14.5+bt*2+wt,  // 圆柱基点的 Y坐标
    zt = hdt+dt,  // 圆柱基点的 Z坐标
    ht = 3.8,  // 圆柱的 高度
    r1 = 2.9,  // 大圆柱的半径
    r2 = 1.65,  // 切削圆柱的半径
    r3 = 0.6,  // 倒角球的半径
) {
  color(boxColor) {  //套用 底盒 颜色
      minkowski() { // 倒角运算函数
      difference() { // 求差运算函数
        translate([xt, yt, zt])
          rotate(a=[0,90,0])
          cylinder(h = ht, r = r1 , $fn = 24); // 创建转轴 大圆柱
        translate([xt, yt, zt])  // 移动到定位点
          rotate(a=[0,90,0])
          cylinder(h = ht, r = r2 , $fn = 16); // 创建转轴 切削圆柱
      }
    sphere(r = r3, $fn = 8); // 使用小球的半径来倒角
    }
  }
}
dihest_3_2();
// 镜像 后加强筋实体 的左侧 的圆柱部分
  translate([-kjqt, 0, 0])  // 镜像后实体的偏移量
    mirror([1, 0, 0]) {   // 沿y轴镜像运算模型
      dihest_3_2();
    }

// 生成 前加强筋 左侧 右边部分
module dihest_3_3(
    zt = -kjqt/2+12.4,  // 点阵 左 X坐标
    zt1 = -kjqt/2+11.8,  // 转轴孔的 X坐标
    yt = -kjqt/2+14.4,  // 点阵 右 X坐标
    ht = 16+bt,  // 点阵 后 Y坐标
    ht1 = 11+dlt+0.6,  // 点阵底部倒角 下顶点 Y坐标
    ht2 = 5.6,  // 点阵 前 Y坐标
    ht3 = 8.5,  // 转轴孔的 Y坐标
    ht4 = 11.6,  // 点阵底部倒角 上顶点 Y坐标
    r1 = 0.6,
    r2 = 1.05,  // 转轴孔的半径
    h1 = 3.2,  // 转轴孔的高
    dh1 = 0.6,  // 点阵底部 Z坐标
    dh2 = dlt,  // 点阵底部倒角 上顶点 Z坐标
    dh3 = hdt+dt-0.6,  // 点阵顶部 Z坐标
    dh4 = hdt+dt-13,  // 转轴孔的 z坐标
    dh5 = hdt+dt-15,  // 腰部 z坐标
) {
  color(boxColor) {  //套用 底盒 颜色
    difference() { // 求差运算函数
      hull() {  //包裹生成 函数
        translate ([zt, ht, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左后 球体
        translate ([yt, ht, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右后 球体
        translate ([zt, ht1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左前 球体
        translate ([yt, ht1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右前 球体
        translate ([zt, ht4, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 底倒角 上顶点 左 球体
        translate ([yt, ht4, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 底倒角 上顶点 右 球体
        translate ([zt, ht2, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左前 球体
        translate ([yt, ht2, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右前 球体
        translate ([zt, ht, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左后 球体
        translate ([yt, ht, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右后 球体
        translate ([zt, ht2, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 腰左前 球体
        translate ([yt, ht2, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 腰右前 球体
      }
    translate([zt1, ht3, dh4])  // 移动到定位点
      rotate(a=[0,90,0])
      cylinder(h = h1, r = r2 , $fn = 16); // 创建转轴 切削圆柱
    }
  }
}
// 对 前加强筋 左侧 右边部分 的点阵部分 进行掏空
  difference() {
    dihest_3_3();
    dihetk();
  }

// 镜像 前加强筋实体 的左侧 左边部分 并掏空
  translate([-kjqt, 0, 0])  // 镜像后实体的偏移量
    mirror([1, 0, 0]) {   // 沿y轴镜像运算模型
      difference() {
        dihest_3_3();
        dihetk();
      }
    }

}
dihest_3();

// 镜像前后加强筋实体 的右侧 部分
  translate([0, 0, 0])  // 镜像后实体的偏移量
    mirror([1, 0, 0]) {   // 沿y轴镜像运算模型
      dihest_3();
    }


//--------------------
//--------------------
//--------------------
//--------------------
//--------------------


// 生成 盖子掏空  部分
module gaitk(
    zt = -lt/2-bt+brt,  // 左 圆心 X坐标
    yt = lt/2+bt-brt,  // 右 圆心 X坐标
    ht = -11-brt,  // 后 圆心 Y坐标
    qt = -11-bt*2-wt+brt,  // 前后 圆心 Y坐标
    r1 = brt-bt/2-dlt-bt/2*0.41,   // 底部梯形的 下圆 半径
    r2 = brt-bt,  // 底部梯形的 上圆 半径
    r3 = brt-bt+0.4,  // 顶部倒角的 上圆 半径
    dh1 = dt,  // 底部梯形的 底 Z 坐标
    dh2 = dlt+bt/2*0.41,  // 底部梯形的 顶 Z 坐标
    dh3 = hut+dt+0.6,  // 顶部倒角的 底 Z 坐标
    h1 = dlt+bt/2*0.41-dt,  // 底部梯形的 高度
    h2 = hut+dt-dlt-bt/2*0.41+0.6,  // 中间圆柱的 高度
    h3 = 0.4,  // 顶部倒角的 高度
) {
  color(gaiColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数 底部梯形+腰部柱体
        translate ([zt, ht, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh2]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt, ht, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh2]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt, qt, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, qt, dh2]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([zt, qt, dh1]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, qt, dh2]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
    }
    hull() {  //包裹生成 函数 顶部倒角
        translate ([zt, ht, dh3]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥

        translate ([yt, ht, dh3]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥

        translate ([yt, qt, dh3]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥

        translate ([zt, qt, dh3]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥

    }
  }
}


// 生成 顶盖  部分
module gai_1(
    zt = -lt/2-bt+brt,  // 左 圆心 X坐标
    yt = lt/2+bt-brt,  // 右 圆心 X坐标
    ht = -11-brt,  // 后 圆心 Y坐标
    qt = -11-bt*2-wt+brt,  // 前后 圆心 Y坐标
    r1 = brt-bt/2-dlt,  // 底部 梯形 底圆半径
    r2 = brt-bt/2,  // 底部 梯形 顶圆半径
    r3 = brt,  // 腰部 梯形 顶圆半径
    r4 = brt-0.4,  // 顶部 倒角 顶圆半径
    r5 = brt-bt/2+0.4,  // 顶部 梯形嵌合体 下半径
    r6 = brt-bt/2-0.6,  // 顶部 梯形嵌合体 上半径
    dh1 = dlt,  // 底部 梯形 顶 Z坐标
    dh2 = hut+dt-bt,  // 腰部 柱体 顶 Z坐标
    dh3 = hut+dt-bt/2,  // 腰部 梯形 顶 Z坐标
    dh4 = hut+dt-0.4,  // 顶部 倒角 下 Z坐标
    dh5 = hut+dt,  // 顶部 梯形嵌合体 下 Z坐标
    h1 = dlt,  // 底部 梯形 高度
    h2 = hut+dt-bt-dlt,  // 腰部 柱体 高度
    h3 = bt/2,  // 腰部 梯形 高度
    h4 = bt/2-0.4,  // 顶部 柱体 高度
    h5 = 0.4,  // 顶部 倒角 高度
    h6 = 1,  // 顶部 梯形嵌合体 高度
) {
  color(gaiColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数 底部梯形+腰部柱体
        translate ([zt, ht, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh1]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt, ht, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh1]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([yt, qt, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, qt, dh1]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
        translate ([zt, qt, 0]) 
          cylinder(h = h1, r1 = r1, r2 = r2, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, qt, dh1]) 
          cylinder(h = h2, r = r2, $fn = 32);  // 创建 圆柱
    }
    hull() {  //包裹生成 函数 腰部梯形+顶部柱体+顶部倒角
        translate ([zt, ht, dh2]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, ht, dh3]) 
          cylinder(h = h4, r = r3, $fn = 32);  // 创建 圆柱
        translate ([zt, ht, dh4]) 
          cylinder(h = h5, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒角梯形圆锥
        translate ([yt, ht, dh2]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, ht, dh3]) 
          cylinder(h = h4, r = r3, $fn = 32);  // 创建 圆柱
        translate ([yt, ht, dh4]) 
          cylinder(h = h5, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒角梯形圆锥
        translate ([yt, qt, dh2]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([yt, qt, dh3]) 
          cylinder(h = h4, r = r3, $fn = 32);  // 创建 圆柱
        translate ([yt, qt, dh4]) 
          cylinder(h = h5, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒角梯形圆锥
        translate ([zt, qt, dh2]) 
          cylinder(h = h3, r1 = r2, r2 = r3, $fn = 32);  // 创建 倒 梯形圆锥
        translate ([zt, qt, dh3]) 
          cylinder(h = h4, r = r3, $fn = 32);  // 创建 圆柱
        translate ([zt, qt, dh4]) 
          cylinder(h = h5, r1 = r3, r2 = r4, $fn = 32);  // 创建 倒角梯形圆锥
    }
    hull() {  //包裹生成 函数 顶部嵌合体
        translate ([zt, ht, dh5]) 
          cylinder(h = h6, r1 = r5, r2 = r6, $fn = 32);  // 创建  梯形圆锥
        translate ([yt, ht, dh5]) 
          cylinder(h = h6, r1 = r5, r2 = r6, $fn = 32);  // 创建  梯形圆锥
        translate ([yt, qt, dh5]) 
          cylinder(h = h6, r1 = r5, r2 = r6, $fn = 32);  // 创建  梯形圆锥
        translate ([zt, qt, dh5]) 
          cylinder(h = h6, r1 = r5, r2 = r6, $fn = 32);  // 创建  梯形圆锥
    }
  }
}

// 对 底盒部分 进行掏空
  difference() {
    gai_1();
    gaitk();
  }


// 生成 左右侧加强筋 前面 部分
module gai_2(
    zt1 = -lt/2-bt+dlt+0.6,  //左边 下倒角 下顶点 X坐标
    zt2 = -lt/2-bt+0.6,  //左边 下倒角 上顶点 X坐标
    yt1 = lt/2+bt-dlt-0.6,  //右边 下倒角 下顶点 X坐标
    yt2 = lt/2+bt-0.6,  //右边 下倒角 上顶点 X坐标
    ht = -11.6-bt-wt/2+jqt/2,  //点阵的 后 Y坐标
    qt = -13.6-bt-wt/2+jqt/2,  //点阵的 前 Y坐标
    r1 = 0.6, 
    dh1 = 0.6,  //点阵的 底 Z坐标
    dh2 = dlt,  //腰部倒角顶点的 Z坐标
    dh3 = hut+dt-1,  //点阵的 顶点 Z坐标
) {
  color(gaiColor) {  //套用 底盒 颜色
    hull() {  //包裹生成 函数
        translate ([zt1, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左前 球体
        translate ([zt1, ht, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左后 球体
        translate ([yt1, ht, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右后 球体
        translate ([yt1, qt, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右前 球体
        translate ([zt2, qt, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中左前 球体
        translate ([zt2, ht, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中左后 球体
        translate ([yt2, ht, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中右后 球体
        translate ([yt2, qt, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 中右前 球体
        translate ([zt2, qt, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左前 球体
        translate ([zt2, ht, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左后 球体
        translate ([yt2, ht, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右后 球体
        translate ([yt2, qt, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右前 球体
    }
  }
}

// 对 左右加强筋 进行掏空
  difference() {
    gai_2();
    gaitk();
  }

// 镜像 左右侧加强筋前面部分 生成后面部分 并掏空
  translate([0, -wt-bt*2-11*2, 0])  //偏移倒 底盒模型的 前后中点
    mirror([0, 1, 0]) {   // 沿X轴镜像运算模型
      difference() {
        gai_2();
        gaitk();
      }
    }

// 命名 前后加强筋 左边部分
module gai_3() {
// 生成 前后加强筋 左侧 右边部分
module gai_3_1(
    zt = -kjqt/2+12.4,  // 点阵 左 X坐标
    yt = -kjqt/2+14.4,  // 点阵 右 X坐标
    zt1 = -kjqt/2+11.8,  // 转轴孔的 X坐标
    yt1 = -8.5,  // 转轴孔的 Y坐标
    qt1 = -11-bt*2-wt+dlt+0.6,  // 前 下倒角 下 Y坐标
    qt2 = -11-bt*2-wt+0.6,  // 前 下倒角 上 Y坐标
    qt3 = -11-bt*2-wt+10,  // 前 上顶点后 Y坐标
    ht1 = -11-bt-10,  // 后 上顶点前 Y坐标
    ht2 =  -5.6,  // 后 上顶点后 Y坐标
    ht3 =  -11.6,  // 后 下倒角 上 Y坐标
    ht4 = -11-dlt-0.6,  // 后 下倒角 下 Y坐标
    r1 = 0.6,
    r2 = 1.05,  // 转轴孔的半径
    h1 = 3.2,  // 转轴孔的高
    dh1 = 0.6,  // 点阵底部 Z坐标
    dh2 = dlt,  // 点阵底部倒角 上顶点 Z坐标
    dh3 = hut+dt-1.6,  // 前 顶部 Z坐标
    dh4 = hut+dt-0.6,  // 后 顶部 Z坐标
    dh5 = hut+dt-8,  // 后 腰部 z坐标
    dh6 = hut+dt-7,  // 转轴孔的 z坐标
) {
  color(gaiColor) {  //套用 底盒 颜色
    difference() { // 求差运算函数
      hull() {  //包裹生成 后 左 左 加强筋
        translate ([zt, ht1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左前 球体
        translate ([yt, ht1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右前 球体
        translate ([zt, ht1, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左前 球体
        translate ([yt, ht1, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右前 球体
        translate ([zt, ht2, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左后 球体
        translate ([yt, ht2, dh4]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右后 球体
        translate ([zt, ht2, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 腰左 球体
        translate ([yt, ht2, dh5]) 
          sphere(r=r1, $fn = 8);  // 创建 腰右 球体
        translate ([zt, ht3, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角上左 球体
        translate ([yt, ht3, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角上右 球体
        translate ([zt, ht4, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角下左 球体
        translate ([yt, ht4, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角下右 球体
      }
    translate([zt1, yt1, dh6])  // 移动到定位点
      rotate(a=[0,90,0])
      cylinder(h = h1, r = r2 , $fn = 16); // 创建转轴 切削圆柱
    }
      hull() {  //包裹生成 前 左 左 加强筋
        translate ([zt, qt3, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底左后 球体
        translate ([yt, qt3, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 底右后 球体
        translate ([zt, qt3, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左后 球体
        translate ([yt, qt3, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右后 球体
        translate ([zt, qt2, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶左前 球体
        translate ([yt, qt2, dh3]) 
          sphere(r=r1, $fn = 8);  // 创建 顶右前 球体
        translate ([zt, qt2, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角上左 球体
        translate ([yt, qt2, dh2]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角上右 球体
        translate ([zt, qt1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角下左 球体
        translate ([yt, qt1, dh1]) 
          sphere(r=r1, $fn = 8);  // 创建 倒角下右 球体
      }
  }
}
// 对 前加强筋 左侧 右边部分 的点阵部分 进行掏空
  difference() {
    gai_3_1();
    gaitk();
  }
// 镜像 前加强筋实体 的左侧 左边部分 并掏空
  translate([-kjqt, 0, 0])  // 镜像后实体的偏移量
    mirror([1, 0, 0]) {   // 沿y轴镜像运算模型
      difference() {
        gai_3_1();
        gaitk();
      }
    }

// 生成 转轴座 左侧 部分
module gai_3_2(
    zx = -kjqt/2-9.1,  // 转轴座的 左 X坐标
    yx = -kjqt/2+9.1,  // 转轴座的 右 X坐标
    axy = -11-bt*2-wt-3.5,  // 转轴座 顶部 的 下凹陷点 Y坐标
    qy = -11-bt*2-wt-7+0.6,  // 转轴座的 前 Y坐标
    hy = -11-bt*2-wt+5,  // 转轴座 后 Y坐标
    zhy = -11-bt*2-wt-0.6,  // 转轴座 轴后 Y坐标

    dz = hut+dt-2.5-7-5,  // 转轴座 后 z坐标
    yz = hut+dt-2.5,  // 转轴座 腰部 z坐标
    qdz = hut+dt,  // 转轴座 前顶点 z坐标
    axz = hut+dt-2.9,  // 转轴座 凹陷点 z坐标
    hdz = hut+dt-0.6,  // 转轴座 凹陷点 z坐标

    r1 = 0.6,  // 倒角球的半径
) {
  color(gaiColor) {  //套用 底盒 颜色
      hull() {  //包裹生成 转轴座 前倒角部分
        translate ([zx, hy, dz]) 
          sphere(r=r1, $fn = 8);  // 创建 底左 球体
        translate ([yx, hy, dz]) 
          sphere(r=r1, $fn = 8);  // 创建 底右 球体
        translate ([zx, qy, yz]) 
          sphere(r=r1, $fn = 8);  // 创建 腰左 球体
        translate ([yx, qy, yz]) 
          sphere(r=r1, $fn = 8);  // 创建 腰右 球体
        translate ([zx, qy, qdz]) 
          sphere(r=r1, $fn = 8);  // 创建 前 顶 左 球体
        translate ([yx, qy, qdz]) 
          sphere(r=r1, $fn = 8);  // 创建 前 顶 右 球体
        translate ([zx, axy, axz]) 
          sphere(r=r1, $fn = 8);  // 创建 凹陷 左 球体
        translate ([yx, axy, axz]) 
          sphere(r=r1, $fn = 8);  // 创建 凹陷 右 球体
      }
      hull() {  //包裹生成 转轴座 后填充部分
        translate ([zx, hy, dz]) 
          sphere(r=r1, $fn = 8);  // 创建 底左 球体
        translate ([yx, hy, dz]) 
          sphere(r=r1, $fn = 8);  // 创建 底右 球体
        translate ([zx, hy, hdz]) 
          sphere(r=r1, $fn = 8);  // 创建 后后 顶 左 球体
        translate ([yx, hy, hdz]) 
          sphere(r=r1, $fn = 8);  // 创建 后后 顶 右 球体
        translate ([zx, zhy, hdz]) 
          sphere(r=r1, $fn = 8);  // 创建 后前 顶 左 球体
        translate ([yx, zhy, hdz]) 
          sphere(r=r1, $fn = 8);  // 创建 后前 顶 右 球体
        translate ([zx, axy, axz]) 
          sphere(r=r1, $fn = 8);  // 创建 凹陷 左 球体
        translate ([yx, axy, axz]) 
          sphere(r=r1, $fn = 8);  // 创建 凹陷 右 球体
      }
  }
}
// 对 转轴座 左侧部分 进行掏空
  difference() {
    gai_3_2();
    gaitk();
  }
// 生成 转轴座 的圆柱部分
module gai_3_3(
    xt = -kjqt/2-9.1,  // 圆柱基点的 X坐标
    yt = -14.5-bt*2-wt,  // 圆柱基点的 Y坐标
    zt = hut+dt,  // 圆柱基点的 Z坐标
    ht = 18.2,  // 圆柱的 高度
    r1 = 2.9,  // 大圆柱的半径
    r2 = 1.8,  // 切削圆柱的半径
    r3 = 0.6,  // 倒角球的半径
) {
  color(gaiColor) {  //套用 底盒 颜色
      minkowski() { // 倒角运算函数
      difference() { // 求差运算函数
        translate([xt, yt, zt])
          rotate(a=[0,90,0])
          cylinder(h = ht, r = r1 , $fn = 24); // 创建转轴 大圆柱
        translate([xt, yt, zt])  // 移动到定位点
          rotate(a=[0,90,0])
          cylinder(h = ht, r = r2 , $fn = 16); // 创建转轴 切削圆柱
      }
    sphere(r = r3, $fn = 8); // 使用小球的半径来倒角
    }
  }
}
gai_3_3();

}
gai_3();

// 命名 左锁扣部分
module suokou_1() {
// 生成 左锁扣 左圆 部分
module suokou_1_1(
    xt = -10-3.5-20,  // 圆的 X坐标
    yt = -11-bt*2-wt-7-10-3.5,  // 圆的 y坐标
    r1 = 2.9,  // 大圆的半径
    r2 = 1.8,  // 切削圆的半径
    ht = 21.8,  // 圆的高度
    dt = 0.6,  // 基准点 Z坐标
    xt1 = -10-3.5-20-1.2,  // 切削长方体的 X坐标
    yt1 = -11-bt*2-wt-7-10-7+3.2-0.6,  // 切削长方体的 y坐标
    ll = 10,  // 切削方块的 长
    ww = 10,  // 切削方块的 宽
    hh = 21.8,  // 切削方块的 高
) {
  color(skColor) {  //套用 锁扣 颜色
    minkowski() { // 倒角运算函数
      difference() { // 求差运算函数
        translate ([xt, yt, dt]) 
          cylinder(h = ht, r = r1, $fn = 32);  // 创建 大圆
        translate ([xt, yt, dt]) 
          cylinder(h = ht, r = r2, $fn = 16);  // 创建 切削圆
        translate ([xt1, yt1, dt]) 
          cube([ll, ww, hh]);  // 创建 切削长方体
      }
    sphere(r = 0.6, $fn = 8); // 使用小球的半径来倒角
    }
  }
}
suokou_1_1();

// 生成 左锁扣 右圆 部分
module suokou_1_2(
    xt = -10-3.5,  // 圆的 X坐标
    yt = -11-bt*2-wt-7-10-3.5,  // 圆的 y坐标
    r1 = 2.9,  // 大圆的半径
    r2 = 1.8,  // 切削圆的半径
    ht = 21.8,  // 圆的高度
    dt = 0.6,  // 基准点 Z坐标
) {
  color(skColor) {  //套用 锁扣 颜色
    minkowski() { // 倒角运算函数
      difference() { // 求差运算函数
        translate ([xt, yt, dt]) 
          cylinder(h = ht, r = r1, $fn = 32);  // 创建 大圆
        translate ([xt, yt, dt]) 
          cylinder(h = ht, r = r2, $fn = 16);  // 创建 切削圆
      }
    sphere(r = 0.6, $fn = 8); // 使用小球的半径来倒角
    }
  }
}
suokou_1_2();


// 生成 左锁扣 连接体 部分
module suokou_1_3(
    dt1 = 0.6,  // 下 的 Z坐标
    dt2 = 22.4,  // 上 的 Z坐标

    xt1 = -10-3.5-20-3.5-10,  // 左 扣手 左 X坐标
    xt2 = -10-3.5-20-2.9,  // 左 扣手 中 X坐标
    xt3 = -10-3.5-20,  // 左 扣手 右 X坐标

    xt4 = -10-3.5-20+2.9-0.6,  // 右连接块 左中 X坐标
    xt5 = -10-3.5-2.9,  // 右连接块 右中 X坐标
    xt6 = -10-3.5,  // 右连接块 右 X坐标

    yt1 = -11-bt*2-wt-7-10-3.5-2.9,  // 左 扣手+连接块 前 Y坐标
    yt2 = -11-bt*2-wt-7-10-3.5-2.9+0.6,  // 左 扣手 中 Y坐标
    yt3 = -11-bt*2-wt-7-10-3.5,  // 左 扣手 后 Y坐标
    yt4 = -11-bt*2-wt-7-10-7+3.2-0.6,  // 接块 后 Y坐标

    r1 = 0.6,

) {
  color(skColor) {  //套用 锁扣 颜色
      hull() {  //包裹生成 左扣手 部分
        translate ([xt1, yt1, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 左前 上 球体
        translate ([xt1, yt1, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 左前 下 球体
        translate ([xt3, yt1, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 右前 上 球体
        translate ([xt3, yt1, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 右前 下 球体
        translate ([xt2, yt3, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 右后 上 球体
        translate ([xt2, yt3, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 右后 下 球体
        translate ([xt1, yt2, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 左后 上 球体
        translate ([xt1, yt2, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 左后 下 球体
      }
      hull() {  //包裹生成 右连接块 部分
        translate ([xt3, yt1, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 左前 上 球体
        translate ([xt3, yt1, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 左前 下 球体
        translate ([xt6, yt1, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 右前 上 球体
        translate ([xt6, yt1, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 右前 下 球体
        translate ([xt5, yt4, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 右后 上 球体
        translate ([xt5, yt4, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 右后 下 球体
        translate ([xt4, yt4, dt2]) 
          sphere(r=r1, $fn = 8);  // 创建 左后 上 球体
        translate ([xt4, yt4, dt1]) 
          sphere(r=r1, $fn = 8);  // 创建 左后 下 球体
      }
  }
}
suokou_1_3();
}
suokou_1();

// 镜像生成 前后加强筋实体+转轴座+左锁扣 的右侧部分
  translate([0, 0, 0])  // 镜像后实体的偏移量
    mirror([1, 0, 0]) {   // 沿y轴镜像运算模型
      gai_3();
      suokou_1();
    }







