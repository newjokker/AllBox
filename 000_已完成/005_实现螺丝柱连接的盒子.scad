include <BOSL2/std.scad>

/* [模型尺寸 / Box Size] */
// 盒子外宽，单位 mm
box_width = 47;            // [30:1:160]
// 盒子外长，单位 mm
box_length = 47;           // [40:1:220]
// 上半盒高度，单位 mm
upper_box_height = 12;     // [6:1:60]
// 下半盒高度，单位 mm
lower_box_height = 20;     // [8:1:100]

/* [盒体结构 / Shell] */
// 四周墙壁厚度
wall_thickness = 2;        // [1:0.2:3]
// 盒子底盖厚度
bottom_thickness = 1.4;    // [0.8, 1.0, 1.2, 1.4, 1.6]
// 盒子转角圆角半径
rounding = 4;              // [3:1:15]
// 盒子外侧闭合端转角样式
box_corner_style = "rounded"; // [flat, rounded]
// 上下盒口错开的唇边高度
lip_height = 2;            // [1:0.5:5]
// 上下盒口错开唇边之间的装配间隙
lip_fit_gap = 0.2;         // [0:0.05:0.8]

/* [螺丝连接 / Screw Mounts] */
// 螺丝规格
screw_size = "m2_5";         // [m2, m2_5, m3, m4, m5]
// 直接攻入塑料的底孔深度（不是已建模螺纹），自动保留柱底实心厚度
screw_pilot_depth = 14;    // [4:1:28]
// 盖子下方沉头座主体高度
lid_countersink_body_height = 2; // [1.2:0.2:6]
// 沉头座额外承力厚度（与主体合为实心座，不再生成空心凸缘）
lid_countersink_rim_height = 1.2;  // [0.4:0.2:3]
// 沉头座外径相对沉头孔大端直径的比例
lid_countersink_outer_scale = 1.2; // [1.1:0.05:2]
// 螺丝柱与盖座轴向间隙，0 为接触承力；正值会留空隙
screw_stack_clearance = 0;       // [0:0.05:1]
// 螺丝柱是否轻微锥形，打印时底部更结实
screw_post_taper = true;   // [true, false]
// 螺丝柱轴心距外边的距离；按脚座直径和圆角自动提高安全下限
screw_post_inset = 6.5;    // [6:0.5:22]

/* [加强筋 / Ribs] */
// 是否增加盒体内部加强筋
ribs_enabled = true;       // [true, false]
// X 方向加强筋位置，数组值表示相对盒子中心的 X 偏移
rib_x_offsets = [-18, 0, 18];
// Y 方向加强筋位置，数组值表示相对盒子中心的 Y 偏移
rib_y_offsets = [-18, 0, 18];
// 加强筋壁厚
rib_thickness = 0.8;         // [0.6:0.1:2.5]

// 盒底筋及侧壁筋凸出内表面的高度
rib_height = 1.2;           // [0.6:0.2:3]
// 螺丝柱到最近两面墙的支撑筋（独立于盒底网格筋）
post_supports_enabled = true;
post_support_thickness = 1.2; // [0.8:0.2:3]

/* [显示与导出 / View] */
preview_mode = "print";    // [print, assembled, open, cutaway, base, lid]
// 爆炸视图沿 Z 向上抬起盖子，0 为闭合
open_distance = 38;        // [0:2:190]
print_part_spacing = 12;   // [4:1:40]

/* [渲染 / Render] */
model_resolution = 96;     // [48, 64, 96, 128]
fast_preview = true;
preview_resolution = 32;   // [24, 32, 48, 64]

/* [Hidden] */
$fn = $preview && fast_preview ? min(model_resolution, preview_resolution) : model_resolution;
eps = 0.02;

function get_param(params, key) =
    let (matches = [for (p = params) if (p[0] == key) p[1]])
        len(matches) == 1
            ? matches[0]
            : assert(false, str("parameter '", key, "' not found"));

function screw_param(screw_size, field) =
    get_param(screw_boss_params, str(screw_size, ".", field));

function countersink_param(screw_size, field) =
    get_param(countersink_hole_params, str(screw_size, ".", field));

screw_boss_params = [
    ["m2.pilot_d", 1.6],
    ["m2.boss_d", 3.8],
    ["m2.foot_d", 6.5],
    ["m2.foot_h", 2.4],
    ["m2.entry_d", 2.4],
    ["m2.entry_h", 0.8],

    ["m2_5.pilot_d", 2.0],
    ["m2_5.boss_d", 4.8],
    ["m2_5.foot_d", 7.5],
    ["m2_5.foot_h", 2.6],
    ["m2_5.entry_d", 3.0],
    ["m2_5.entry_h", 0.9],

    ["m3.pilot_d", 2.5],
    ["m3.boss_d", 5.6],
    ["m3.foot_d", 9.0],
    ["m3.foot_h", 3.2],
    ["m3.entry_d", 3.8],
    ["m3.entry_h", 1.0],

    ["m4.pilot_d", 3.3],
    ["m4.boss_d", 7.2],
    ["m4.foot_d", 11.5],
    ["m4.foot_h", 4.0],
    ["m4.entry_d", 5.0],
    ["m4.entry_h", 1.2],

    ["m5.pilot_d", 4.2],
    ["m5.boss_d", 9.0],
    ["m5.foot_d", 14.0],
    ["m5.foot_h", 4.8],
    ["m5.entry_d", 6.2],
    ["m5.entry_h", 1.4]
];

countersink_hole_params = [
    ["m2.shaft_clearance_d", 2.3],
    ["m2.countersink_d", 4.4],
    ["m2.countersink_depth", 1.1],
    ["m2.countersink_angle", 90],

    ["m2_5.shaft_clearance_d", 2.8],
    ["m2_5.countersink_d", 5.5],
    ["m2_5.countersink_depth", 1.35],
    ["m2_5.countersink_angle", 90],

    ["m3.shaft_clearance_d", 3.4],
    ["m3.countersink_d", 6.5],
    ["m3.countersink_depth", 1.55],
    ["m3.countersink_angle", 90],

    ["m4.shaft_clearance_d", 4.5],
    ["m4.countersink_d", 8.5],
    ["m4.countersink_depth", 2.0],
    ["m4.countersink_angle", 90],

    ["m5.shaft_clearance_d", 5.5],
    ["m5.countersink_d", 10.5],
    ["m5.countersink_depth", 2.5],
    ["m5.countersink_angle", 90]
];

// 两个半盒均以闭合底面 Z=0、开口朝上建模；装配时统一翻转上盖。
// 上盖闭合外表面 Z = lower_box_height + upper_box_height。
head_d = countersink_param(screw_size, "countersink_d");
shaft_d = countersink_param(screw_size, "shaft_clearance_d");
pilot_d = screw_param(screw_size, "pilot_d");
boss_d = screw_param(screw_size, "boss_d");
foot_d = screw_param(screw_size, "foot_d");
entry_d = screw_param(screw_size, "entry_d");
entry_h = screw_param(screw_size, "entry_h");
// 按两端直径推导 90° 锥孔深度，避免表格深度和锥角互相矛盾。
sink_depth = (head_d - shaft_d) / 2;
seat_h = lid_countersink_body_height + lid_countersink_rim_height;
seat_d = max(head_d * lid_countersink_outer_scale, head_d + 2 * wall_thickness);
post_h = lower_box_height + upper_box_height - 2 * bottom_thickness
         - seat_h - screw_stack_clearance;
pilot_depth = min(screw_pilot_depth, post_h - 1.2);
// 脚座和上盖承力座都必须完整落在圆角内腔中；四柱使用同一坐标。
mount_r = max(foot_d, seat_d) / 2;
inner_r = max(0, rounding - wall_thickness);
effective_inset = max(screw_post_inset,
    wall_thickness + mount_r + 0.4,
    rounding + (mount_r + 0.4 - inner_r) / sqrt(2));
post_xy = [for (x=[-1,1], y=[-1,1])
    [x * (box_width / 2 - effective_inset), y * (box_length / 2 - effective_inset)]];
lip_wall = (wall_thickness - lip_fit_gap) / 2;
lip_recess_wall = (wall_thickness + lip_fit_gap) / 2;
// 径向间隙独立于轴向间隙，保证盖子不是靠唇边顶端顶住。
lip_z_gap = 0.2;
foot_h = min(screw_param(screw_size, "foot_h"), post_h / 3);
valid_rib_x = [for (x=rib_x_offsets)
    if (abs(x) + rib_thickness / 2 < box_width / 2 - rounding) x];
valid_rib_y = [for (y=rib_y_offsets)
    if (abs(y) + rib_thickness / 2 < box_length / 2 - rounding) y];

assert(box_width > 2 * rounding && box_length > 2 * rounding,
       "外宽/外长必须大于两倍圆角半径");
assert(rounding >= wall_thickness && bottom_thickness > 0 && wall_thickness > 0,
       "圆角半径不得小于壁厚，壁厚与底厚必须为正");
assert(min(lower_box_height, upper_box_height) > bottom_thickness + lip_height + lip_z_gap,
       "半盒高度不足：需要容纳底板、唇边及轴向间隙");
assert(lip_height > 0 && lip_fit_gap >= 0 && lip_wall >= 0.4,
       "唇边过薄：请增大壁厚或减小配合间隙");
assert(seat_h > 0 && bottom_thickness + seat_h > sink_depth + 0.8,
       "沉头座厚度不足，沉孔后至少保留 0.8 mm 承力材料");
assert(seat_h + bottom_thickness < upper_box_height - lip_height - lip_z_gap,
       "上盖过矮，沉头座侵入盒口区域；请增加上盖高度或减小座高");
assert(post_h > 2 && pilot_depth > entry_h && screw_pilot_depth > 0,
       "螺丝柱/底孔太短，请增加盒高或减小盖座高度");
assert(screw_stack_clearance >= 0 && lid_countersink_outer_scale > 1,
       "柱座间隙必须非负，盖座外径比例必须大于 1");
assert(min(box_width, box_length) - 2 * effective_inset > 2 * mount_r + 0.8,
       "四个螺丝座重叠：请增大盒子、减小内缩距离或选用更小螺丝");
assert(rib_thickness > 0 && rib_height > 0 && post_support_thickness > 0,
       "加强筋尺寸必须为正");
assert(box_corner_style == "flat" || box_corner_style == "rounded", "未知转角样式");
assert(in_list(preview_mode, ["print", "assembled", "open", "cutaway", "base", "lid"]),
       "未知显示模式");
assert(open_distance >= 0 && print_part_spacing > 0, "显示间距不能为负，打印间距必须为正");
if (effective_inset > screw_post_inset)
    echo(str("螺丝柱安全内缩调整为 ", effective_inset, " mm（距外边）"));
if (pilot_depth < screw_pilot_depth)
    echo(str("底孔深度限制为 ", pilot_depth, " mm，柱底保留 1.2 mm"));
if (ribs_enabled && (len(valid_rib_x) < len(rib_x_offsets) || len(valid_rib_y) < len(rib_y_offsets)))
    echo("已跳过圆角区或盒外的加强筋位置");
// 沉头螺丝标称长度按含头总长计；这里只报告几何空间，不代替螺纹试配。
echo(str("盖外表面到柱顶 ", bottom_thickness + seat_h + screw_stack_clearance,
         " mm，底孔深度 ", pilot_depth,
         " mm；留 1 mm 孔底余量时螺丝总长不超过 ",
         bottom_thickness + seat_h + screw_stack_clearance + pilot_depth - 1, " mm"));

module outline(inset=0) {
    rect([box_width - 2 * inset, box_length - 2 * inset],
         rounding=max(0, rounding - inset));
}

module shell(h) {
    if (box_corner_style == "flat")
        difference() {
            linear_extrude(h) outline();
            translate([0,0,bottom_thickness])
                linear_extrude(h) outline(wall_thickness);
        }
    else {
        // 底面仍落在 Z=0。内腔保持竖直壁，闭合端圆角限于底厚，避免削穿底板。
        edge_r = min(rounding, bottom_thickness);
        difference() {
            // 用四分之一圆弧截面恢复外轮廓，保留真正圆底角和大尺寸 XY 圆角。
            hull() {
                translate([0,0,edge_r])
                    linear_extrude(h-edge_r) outline();
                for (i=[0:max(8,ceil($fn/4))]) {
                    a = 90 * i / max(8,ceil($fn/4));
                    translate([0,0,edge_r*(1-cos(a))])
                        linear_extrude(eps) outline(edge_r*(1-sin(a)));
                }
            }
            translate([0,0,bottom_thickness])
                linear_extrude(h) outline(wall_thickness);
        }
    }
}

module base_shell() {
    // 仅合并简单壳体，消除 F5 中唇边与外壁共面造成的闪烁/假裂缝。
    render(convexity=8) union() {
        shell(lower_box_height);
        translate([0,0,lower_box_height-eps])
            linear_extrude(lip_height+eps)
                difference() { outline(); outline(lip_wall); }
    }
}

module lid_shell() {
    render(convexity=8) difference() {
        shell(upper_box_height);
        translate([0,0,upper_box_height-lip_height-lip_z_gap])
            linear_extrude(lip_height+lip_z_gap+eps)
                difference() { outline(-eps); outline(lip_recess_wall); }
    }
}

// 低矮网格筋：交叉处直接融合，不另造环形节点。
// 与底板、侧壁分别有明确重叠，且在唇边以下停止。
module shell_ribs(h) {
    if (ribs_enabled)
        intersection() {
            translate([0,0,bottom_thickness-eps])
                linear_extrude(h-bottom_thickness-lip_height-lip_z_gap)
                    outline(wall_thickness-eps);
            union() {
                for (x=valid_rib_x) {
                    translate([x,0,bottom_thickness-eps])
                        cuboid([rib_thickness,box_length, rib_height+eps], anchor=BOT);
                    for (sy=[-1,1])
                        translate([x, sy*(box_length/2-wall_thickness-rib_height/2), bottom_thickness-eps])
                            cuboid([rib_thickness,rib_height+2*eps,h],anchor=BOT);
                }
                for (y=valid_rib_y) {
                    translate([0,y,bottom_thickness-eps])
                        cuboid([box_width,rib_thickness,rib_height+eps],anchor=BOT);
                    for (sx=[-1,1])
                        translate([sx*(box_width/2-wall_thickness-rib_height/2),y,bottom_thickness-eps])
                            cuboid([rib_height+2*eps,rib_thickness,h],anchor=BOT);
                }
            }
        }
}

module boss_solid() {
    bottom_d = screw_post_taper ? boss_d*1.08 : boss_d;
    union() {
        // 有限直径的锥形脚座，替代高细分环面差集；脚座尺寸真正取自规格表。
        cylinder(h=foot_h, d1=foot_d, d2=bottom_d);
        translate([0,0,foot_h-eps])
            cylinder(h=post_h-foot_h+eps, d1=bottom_d, d2=boss_d);
    }
}

module pilot_mask() {
    translate([0,0,post_h-pilot_depth])
        cylinder(h=pilot_depth+eps,d=pilot_d);
    translate([0,0,post_h-entry_h])
        cylinder(h=entry_h+eps,d1=pilot_d,d2=entry_d);
}

// 支撑筋连接柱体和最近两面墙，留在下盒开口以下。
module post_supports() {
    if (post_supports_enabled)
        for (p=post_xy) {
            x_end = sign(p.x)*(box_width/2-wall_thickness+eps);
            y_end = sign(p.y)*(box_length/2-wall_thickness+eps);
            support_h = min(post_h-foot_h, lower_box_height-bottom_thickness-lip_height-lip_z_gap);
            translate([(p.x+x_end)/2,p.y,bottom_thickness-eps])
                cuboid([abs(x_end-p.x),post_support_thickness,support_h+eps], anchor=BOT);
            translate([p.x,(p.y+y_end)/2,bottom_thickness-eps])
                cuboid([post_support_thickness,abs(y_end-p.y),support_h+eps], anchor=BOT);
        }
}

module lower_box() {
    difference() {
        union() {
            base_shell();
            shell_ribs(lower_box_height);
            post_supports();
            for (p=post_xy)
                translate([p.x,p.y,bottom_thickness-eps])
                    // 补回重叠厚度，保持柱顶装配基准不变。
                    union() {
                        cylinder(h=eps,d=foot_d);
                        translate([0,0,eps]) boss_solid();
                    }
        }
        // 最后统一打孔，避免加强筋或底板填回盲孔。
        for (p=post_xy)
            translate([p.x,p.y,bottom_thickness]) pilot_mask();
    }
}

module lid_hole_mask() {
    translate([0,0,-eps])
        cylinder(h=bottom_thickness+seat_h+2*eps,d=shaft_d);
    // 外侧 Z=0 是大端，向盖内缩小；真实 90° 沉头。
    translate([0,0,-eps])
        cylinder(h=sink_depth+eps,d1=head_d+2*eps,d2=shaft_d);
}

module upper_lid() {
    difference() {
        union() {
            lid_shell();
            shell_ribs(upper_box_height);
            for (p=post_xy)
                translate([p.x,p.y,bottom_thickness-eps])
                    cylinder(h=seat_h+eps,d=seat_d);
        }
        for (p=post_xy)
            translate([p.x,p.y,0]) lid_hole_mask();
    }
}

module assembled_lid(lift=0) {
    translate([0,0,lower_box_height+upper_box_height+lift])
        rotate([180,0,0]) upper_lid();
}
module closed_assembly_view() {
    lower_box();
    assembled_lid();
}

if (preview_mode == "base") lower_box();
else if (preview_mode == "lid") upper_lid();
else if (preview_mode == "assembled") closed_assembly_view();
else if (preview_mode == "open") {
    lower_box();
    assembled_lid(open_distance);
}
else if (preview_mode == "cutaway")
    intersection() {
        closed_assembly_view();
        // 剖切面穿过一排螺丝轴线，直接显示沉头孔、柱顶接触面和盲孔底。
        translate([-box_width,-box_length, -eps])
            cube([1.5*box_width-effective_inset,2*box_length,
                  lower_box_height+upper_box_height+2*eps]);
    }
else {
    lower_box();
    translate([box_width+print_part_spacing,0,0]) upper_lid();
}
