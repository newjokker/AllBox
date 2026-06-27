include <BOSL2/std.scad>


module FingerNotch(upper_length=10, down_length=20, h=5, thick=2){

    prismoid(
        size1 = [upper_length, thick],  // 下底：宽20，长10
        size2 = [down_length, thick],  // 上底：宽10，长10（从正面看就是梯形）
        h = h                           // 高度（柱体的长度）
    );

}

FingerNotch(upper_length=15, down_length=25, h=4, thick=10, anchor=[0, 1,1]);