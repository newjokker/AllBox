
include <BOSL2/std.scad>
include <BOSL2/threading.scad>
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

// https://github.com/BelfrySCAD/BOSL2/wiki



module boxLid(tkns, innerSize, innerRounding, isMask=false, ofs = 0.1){
  ofs = isMask ? ofs : 0;
  
  rd=isMask ? innerRounding : innerRounding+0.4;
  
  lidSizeY = innerSize.y+tkns;
  
  lidSizeTop = [innerSize.x, lidSizeY, tkns/2]-[tkns*2, tkns, 0] + [ofs*2, ofs*2, ofs*2];
  lidSizeBot = [innerSize.x, lidSizeY, tkns] + [ofs*2, ofs*2, ofs*2];
  faceSize= [innerSize.x, innerSize.y, tkns] + [ofs*2+tkns*2, ofs*2+tkns*2, ofs*2];
  
  ymove(-(innerSize.y)/2-ofs-tkns)
  zmove(tkns*2-ofs)
  cuboid(size=lidSizeTop, rounding=rd, edges="Z", except=FRONT, anchor=BOTTOM+FRONT, $fn=32);
  
  ymove(-innerSize.y/2-ofs-tkns)
  zmove(tkns)
  prismoid([lidSizeBot.x, lidSizeBot.y], [lidSizeTop.x, lidSizeTop.y], shift=[0, -tkns/2], rounding=[rd,rd,0,0], h=tkns, anchor=BOTTOM+FRONT, $fn=32);
  
  ymove(-innerSize.y/2-ofs-tkns)
  zmove(-ofs)
  cuboid(size=lidSizeBot, rounding=rd, edges="Z", except=FRONT, anchor=BOTTOM+FRONT, $fn=32);
  
  zmove(-ofs+tkns*2.5)
  cuboid(size=faceSize, anchor=BOTTOM, rounding=innerRounding+ofs+tkns, edges="Z", $fn=32);
}

function getLidH(tkns) = tkns * 2.5;
function getOfsInnerSize(innerSize, ofs) = innerSize + [ofs*2, ofs*2, ofs*2];
function getBoxSize(tkns, innerSize, ofs) = getOfsInnerSize(innerSize, ofs) + [tkns*2, tkns*2, tkns+getLidH(tkns)];

module box(tkns, innerSize, innerRounding, ofs=0.1) 
{
  lidH = getLidH(tkns);
  echo(lidH = lidH);
  ofsInnerSize = getOfsInnerSize(innerSize, ofs);
  boxSize= getBoxSize(tkns, innerSize, ofs);
  difference() {
    cuboid(size=boxSize, anchor=BOTTOM, rounding=innerRounding+ofs+tkns, edges="Z", $fn=32);
    zmove(tkns)
    cuboid(size=ofsInnerSize, anchor=BOTTOM, rounding=innerRounding, edges="Z", $fn=32);
    
    zmove(tkns+ofsInnerSize.z)
    boxLid(tkns, ofsInnerSize, innerRounding, true);
  }  
}

module boxHolder(thingSize, tkns=1.5, ofs = 0.5) 
{
  sz = [thingSize.x+ofs*2+tkns*2, thingSize.y+ofs*2+tkns*2, thingSize.z/2+tkns*2];
  
  szInner = sz-[tkns*2, tkns*2, 0];
  
  difference() {
    cuboid(size=sz, anchor=BOTTOM, rounding=tkns, except=BACK, $fn=32);
    zmove(tkns)
    
    cuboid(size=szInner+[0,0,0.1], anchor=BOTTOM);
    
    ymove(-tkns)
    zmove(tkns+10)
    cuboid(size=szInner+[tkns*2+0.2, tkns*2,-10], chamfer=szInner.y/2-tkns*2, edges=BOTTOM+BACK, anchor=BOTTOM);
    
    zmove(-0.1)
    cuboid(size=szInner+[-tkns*4+0.2, -tkns*2, 0], chamfer=szInner.y/2-tkns*2, edges="Z", anchor=BOTTOM);
  }
  
}


tkns=1.5;
innerRounding = 2;
ofs=0.1;
innerSize=[47.5, 62, 16];
innerOfsSize = innerSize + [0.2, 0.2, 0.1];
boxSize= getBoxSize(tkns, innerOfsSize, ofs)+[0,0,0.1+tkns];

holePos = 34;
holeD = 9;
// 盖子
zmove(innerOfsSize.z+tkns+0.2+tkns*3)
boxLid(tkns, innerOfsSize, innerRounding, false, ofs);
// 盒子
difference() {
  box(tkns, innerOfsSize, innerRounding, ofs);
  // 开孔
  ymove(-innerOfsSize.y/2+holePos)
  zmove(tkns+6)
  xcyl(d=holeD, l=boxSize.x+0.2, anchor=BOTTOM, $fn=6);
}

boxHolderOfs = 0.5;
// 安装托盘
xmove(boxSize.y/2 + boxSize.x/2+10)
boxHolder([boxSize.y, boxSize.z, boxSize.x], tkns, boxHolderOfs);
