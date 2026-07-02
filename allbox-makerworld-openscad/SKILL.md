---
name: allbox-makerworld-openscad
description: Use when editing or creating OpenSCAD box models in the AllBox project for Bambu MakerWorld / MakerLab Parametric Model Maker compatibility. Applies to `.scad` files that should expose clean Customizer parameters, hide derived variables, preserve the project's BOSL2-based Chinese-commented style, and keep box connection mechanisms printable and understandable.
---

# AllBox MakerWorld OpenSCAD

## Core Workflow

1. Read the target `.scad` file before editing. Preserve its existing geometry style, naming patterns, Chinese comments, and BOSL2 usage.
2. Keep user-facing parameters at the top of the main file before any module/function body or `{`.
3. Write MakerWorld-compatible Customizer parameters as simple literals only: numbers, booleans, strings, or numeric vectors of up to four items.
4. Move derived values, computed dimensions, helper constants, and internal switches after `/* [Hidden] */`.
5. Validate with a lightweight OpenSCAD export first, such as `openscad -o /tmp/model.ast file.scad` or `openscad -o /tmp/model.csg file.scad`. Use STL export when geometry risk is high, but expect complex hinge models to be slow.

## MakerWorld Parameter Style

Use block comments for groups:

```scad
/* [模型尺寸 / Box Size] */
```

Use a directly adjacent Chinese description comment above each exposed parameter:

```scad
// 盒子外宽，单位 mm
box_width = 50;             // [30:1:120]
```

Use these widget formats:

```scad
value = 10;                 // [0:1:100]
ratio = 0.5;                // [0.1:0.05:1]
choice = 64;                // [48, 64, 96, 128]
mode = "closed";            // [closed, open, exploded]
enabled = true;
```

Avoid exposing these as Customizer parameters:

```scad
box_size = [box_width, box_length, box_height];
hinge_length = box_length * 3 / 4;
extra_height = abs(lower_box_height - upper_box_height) / 2 + 2;
```

Instead expose simple controls, then derive internals after `/* [Hidden] */`:

```scad
/* [模型尺寸 / Box Size] */
// 盒子外长，单位 mm
box_length = 150;           // [60:1:250]
// 铰链长度，建议小于盒子外长
hinge_length = 112.5;       // [40:0.5:220]

/* [Hidden] */
box_size = [box_width, box_length, box_height];
```

## AllBox Code Style

- Prefer BOSL2 primitives and attachment patterns already used in the repo, such as `cuboid`, `rect_tube`, `prismoid`, `attachable`, `attach`, `position`, and `orient`.
- Keep public parameter names short, stable, and English snake_case; explain them with Chinese comments.
- Keep module names descriptive and English snake_case, such as `box_body`, `friction_bump`, `hinged_box_half`.
- Keep box models structured around three layers: lower body, upper body/lid, and connection mechanism.
- Keep connection mechanisms in separate top-level `.scad` files when adding a new connection type.
- Use Chinese comments for design intent, fit warnings, and print-tuning notes. Avoid noisy comments for obvious transforms.
- Preserve preview controls such as `open_angle` when they help MakerWorld users understand the model.

## Geometry And Print Fit

- Treat mechanism issues as assembly/fit problems first, not only syntax problems.
- For hinges, expose clearance, gap, segment count, offset, and arm-height controls when useful.
- For lips, friction bumps, snap fits, rails, magnets, or screw posts, keep fit-critical dimensions adjustable with conservative ranges.
- Avoid ranges that allow obviously broken geometry, such as wall thickness larger than half the box width.
- If a parameter affects multiple derived dimensions, expose one user-friendly parameter and compute the dependent values in Hidden.
- For hinge alignment, do not expose height-derived compensation as fixed Customizer values. Expose only small `*_adjust` controls, then compute values such as hinge arm extra height and upper hinge Z lift in Hidden from `lower_box_height` and `upper_box_height`.

## Validation Notes

Run at least one parse/evaluation check after editing:

```bash
openscad -o /tmp/allbox_check.ast target.scad
openscad -o /tmp/allbox_check.csg target.scad
```

For final printable confidence, export STL when feasible:

```bash
openscad -o /tmp/allbox_check.stl target.scad
```

If STL export is too slow for complex hinges, report that AST/CSG passed and STL was not completed.
