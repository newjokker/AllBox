#!/usr/bin/env python3
import argparse
import json
import math
import re
import subprocess
import tempfile
import zipfile
from collections import OrderedDict
from pathlib import Path
from xml.sax.saxutils import escape


DEFAULT_GRAY = "#B4B4B4FF"


def run(cmd, quiet=False):
    if quiet:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        subprocess.run(cmd, check=True)


def sanitize_name(name):
    name = re.sub(r"[^A-Za-z0-9_.-]+", "_", name).strip("_")
    return name or "part"


def rgba_to_hex(values):
    nums = [float(v) for v in values[:4]]
    while len(nums) < 4:
        nums.append(1.0)
    channels = []
    for value in nums:
        if value > 1:
            value = value / 255.0
        value = max(0.0, min(1.0, value))
        channels.append(round(value * 255))
    return "#{:02X}{:02X}{:02X}{:02X}".format(*channels)


def find_matching_brace(text, open_index):
    depth = 0
    in_string = False
    escape_next = False
    for idx in range(open_index, len(text)):
        ch = text[idx]
        if in_string:
            if escape_next:
                escape_next = False
            elif ch == "\\":
                escape_next = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return idx
    raise ValueError("Unmatched brace in generated CSG")


def extract_color_blocks(csg_text):
    pattern = re.compile(r"color\s*\(\s*\[([^\]]+)\]\s*\)\s*\{", re.MULTILINE)
    pos = 0
    uncolored = []
    color_blocks = []

    while True:
        match = pattern.search(csg_text, pos)
        if not match:
            uncolored.append(csg_text[pos:])
            break
        uncolored.append(csg_text[pos:match.start()])
        open_brace = csg_text.find("{", match.end() - 1)
        close_brace = find_matching_brace(csg_text, open_brace)
        rgba = [v.strip() for v in match.group(1).split(",")]
        body = csg_text[open_brace + 1:close_brace].strip()
        if body:
            color_blocks.append((rgba_to_hex(rgba), body))
        pos = close_brace + 1

    return color_blocks, "".join(uncolored).strip()


def contains_geometry(text):
    return bool(re.search(
        r"\b(cube|sphere|cylinder|polyhedron|polygon|circle|square|text|linear_extrude|rotate_extrude|surface|import)\s*\(",
        text,
    ))


def parse_ascii_stl(path):
    vertices = []
    triangles = []
    vertex_index = {}
    current = []

    def add_vertex(coords):
        key = tuple(round(float(v), 6) for v in coords)
        if key not in vertex_index:
            vertex_index[key] = len(vertices)
            vertices.append(key)
        return vertex_index[key]

    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        for raw in fh:
            line = raw.strip()
            if line.startswith("vertex "):
                current.append(add_vertex(line.split()[1:4]))
            elif line == "endfacet":
                if len(current) == 3:
                    a, b, c = current
                    va, vb, vc = vertices[a], vertices[b], vertices[c]
                    ab = [vb[i] - va[i] for i in range(3)]
                    ac = [vc[i] - va[i] for i in range(3)]
                    cross = (
                        ab[1] * ac[2] - ab[2] * ac[1],
                        ab[2] * ac[0] - ab[0] * ac[2],
                        ab[0] * ac[1] - ab[1] * ac[0],
                    )
                    if math.sqrt(sum(v * v for v in cross)) > 1e-9:
                        triangles.append((a, b, c))
                current = []
    return vertices, triangles


def normal_for_triangle(vertices, tri):
    va, vb, vc = [vertices[i] for i in tri]
    ab = [vb[i] - va[i] for i in range(3)]
    ac = [vc[i] - va[i] for i in range(3)]
    normal = (
        ab[1] * ac[2] - ab[2] * ac[1],
        ab[2] * ac[0] - ab[0] * ac[2],
        ab[0] * ac[1] - ab[1] * ac[0],
    )
    length = math.sqrt(sum(v * v for v in normal))
    if length <= 1e-9:
        return (0, 0, 0)
    return tuple(v / length for v in normal)


def write_ascii_stl(path, name, vertices, triangles):
    with path.open("w", encoding="utf-8") as fh:
        fh.write(f"solid {name}\n")
        for tri in triangles:
            normal = normal_for_triangle(vertices, tri)
            fh.write(f"  facet normal {normal[0]:.6g} {normal[1]:.6g} {normal[2]:.6g}\n")
            fh.write("    outer loop\n")
            for idx in tri:
                x, y, z = vertices[idx]
                fh.write(f"      vertex {x:.6f} {y:.6f} {z:.6f}\n")
            fh.write("    endloop\n")
            fh.write("  endfacet\n")
        fh.write(f"endsolid {name}\n")


def shifted_vertices(vertices, offset):
    return [(x + offset[0], y + offset[1], z + offset[2]) for x, y, z in vertices]


def compute_offset(meshes, center_x, center_y, auto_center):
    all_vertices = [vertex for _, _, vertices, _ in meshes for vertex in vertices]
    if not all_vertices:
        return (0, 0, 0)
    xs = [v[0] for v in all_vertices]
    ys = [v[1] for v in all_vertices]
    zs = [v[2] for v in all_vertices]
    z_offset = -min(zs)
    if not auto_center:
        return (0, 0, z_offset)
    return (
        center_x - ((min(xs) + max(xs)) / 2.0),
        center_y - ((min(ys) + max(ys)) / 2.0),
        z_offset,
    )


def mesh_xml(object_id, name, vertices, triangles, material_group, material_index):
    out = [f'<object id="{object_id}" name="{escape(name)}" type="model">', "<mesh>", "<vertices>"]
    for x, y, z in vertices:
        out.append(f'<vertex x="{x:.6f}" y="{y:.6f}" z="{z:.6f}"/>')
    out.append("</vertices>")
    out.append("<triangles>")
    for a, b, c in triangles:
        out.append(f'<triangle v1="{a}" v2="{b}" v3="{c}" pid="{material_group}" p1="{material_index}"/>')
    out.append("</triangles>")
    out.append("</mesh></object>")
    return "\n".join(out)


def build_3mf(output, title, meshes, offset):
    material_group = 1
    resources = [f'<basematerials id="{material_group}">']
    for _, color, _, _ in meshes:
        resources.append(f'<base name="{escape(color)}" displaycolor="{color}"/>')
    resources.append("</basematerials>")

    build_items = []
    object_settings = []
    for idx, (name, color, vertices, triangles) in enumerate(meshes):
        object_id = idx + 2
        extruder = idx + 1
        shifted = shifted_vertices(vertices, offset)
        resources.append(mesh_xml(object_id, name, shifted, triangles, material_group, idx))
        build_items.append(f'<item objectid="{object_id}"/>')
        object_settings.append(f'''<object id="{object_id}">
  <metadata key="name" value="{escape(name)}"/>
  <metadata key="extruder" value="{extruder}"/>
</object>''')

    colors_rgb = [color[:7] for _, color, _, _ in meshes]
    project_settings = {
        "filament_type": ["PLA"] * len(meshes),
        "filament_colour": colors_rgb,
        "filament_diameter": ["1.75"] * len(meshes),
        "filament_density": ["1.24"] * len(meshes),
    }

    model = f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US"
 xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02"
 xmlns:m="http://schemas.microsoft.com/3dmanufacturing/material/2015/02">
<metadata name="Title">{escape(title)}</metadata>
<metadata name="Application">BambuStudio-02.06.00.51</metadata>
<resources>
{chr(10).join(resources)}
</resources>
<build>
{chr(10).join(build_items)}
</build>
</model>
'''

    content_types = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
<Default Extension="config" ContentType="application/octet-stream"/>
</Types>
'''

    rels = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
'''

    model_settings = f'''<?xml version="1.0" encoding="UTF-8"?>
<config>
{chr(10).join(object_settings)}
<plate>
  <metadata key="plater_id" value="1"/>
  <metadata key="plater_name" value=""/>
  <metadata key="filament_map_mode" value="Auto For Flush"/>
  <metadata key="filament_maps" value="{",".join(str(i + 1) for i in range(len(meshes)))}"/>
</plate>
</config>
'''

    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types)
        zf.writestr("_rels/.rels", rels)
        zf.writestr("3D/3dmodel.model", model)
        zf.writestr("Metadata/project_settings.config", json.dumps(project_settings, indent=2))
        zf.writestr("Metadata/model_settings.config", model_settings)


def generate_meshes(scad_path, output_parts_dir, keep_uncolored, quiet, openscad_defs):
    meshes = []
    output_parts_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="scad_color_to_bambu_") as tmp:
        tmpdir = Path(tmp)
        csg_path = tmpdir / "model.csg"
        cmd = ["openscad", "-o", str(csg_path)]
        for define in openscad_defs:
            cmd.extend(["-D", define])
        cmd.append(str(scad_path))
        run(cmd, quiet=quiet)

        color_blocks, uncolored = extract_color_blocks(csg_path.read_text(encoding="utf-8", errors="ignore"))
        grouped = OrderedDict()
        for color, body in color_blocks:
            grouped.setdefault(color, []).append(body)

        if keep_uncolored and uncolored and contains_geometry(uncolored):
            grouped.setdefault(DEFAULT_GRAY, []).append(uncolored)

        if not grouped:
            raise RuntimeError("No color() blocks found in OpenSCAD CSG output")

        for idx, (color, bodies) in enumerate(grouped.items(), start=1):
            name = f"part_{idx:02d}_{color[1:7]}"
            part_scad = tmpdir / f"{name}.scad"
            part_stl = tmpdir / f"{name}.stl"
            part_scad.write_text("union() {\n" + "\n".join(bodies) + "\n}\n", encoding="utf-8")
            try:
                run(["openscad", "--export-format", "asciistl", "-o", str(part_stl), str(part_scad)], quiet=quiet)
            except subprocess.CalledProcessError:
                print(f"Skip empty or invalid part: {name}")
                continue
            vertices, triangles = parse_ascii_stl(part_stl)
            if not vertices or not triangles:
                print(f"Skip empty part: {name}")
                continue
            meshes.append((name, color, vertices, triangles))

    if not meshes:
        raise RuntimeError("No non-empty meshes were generated from color blocks")
    return meshes


def main():
    parser = argparse.ArgumentParser(
        description="Convert top-level color() blocks in a SCAD file to a Bambu Studio multi-extruder 3MF."
    )
    parser.add_argument("input", help="Input .scad file")
    parser.add_argument("-o", "--output", help="Output .3mf path")
    parser.add_argument("--parts-dir", help="Also write centered STL parts to this directory")
    parser.add_argument("--center-x", type=float, default=128.0, help="Target bed center X in mm")
    parser.add_argument("--center-y", type=float, default=128.0, help="Target bed center Y in mm")
    parser.add_argument("--no-auto-center", action="store_true", help="Keep original XY coordinates")
    parser.add_argument("--drop-uncolored", action="store_true", help="Ignore geometry outside top-level color() blocks")
    parser.add_argument("-D", dest="defines", action="append", default=[], help="Pass -D definitions to OpenSCAD")
    parser.add_argument("--quiet", action="store_true", help="Hide OpenSCAD output")
    args = parser.parse_args()

    scad_path = Path(args.input).resolve()
    if not scad_path.exists():
        raise FileNotFoundError(scad_path)

    output = Path(args.output).resolve() if args.output else scad_path.with_suffix(".bambu.3mf")
    parts_dir = Path(args.parts_dir).resolve() if args.parts_dir else output.with_suffix("").parent / f"{output.stem}_parts"

    meshes = generate_meshes(
        scad_path=scad_path,
        output_parts_dir=parts_dir,
        keep_uncolored=not args.drop_uncolored,
        quiet=args.quiet,
        openscad_defs=args.defines,
    )
    offset = compute_offset(meshes, args.center_x, args.center_y, auto_center=not args.no_auto_center)

    for name, _, vertices, triangles in meshes:
        write_ascii_stl(parts_dir / f"{sanitize_name(name)}.stl", name, shifted_vertices(vertices, offset), triangles)

    build_3mf(output, scad_path.stem, meshes, offset)
    print(f"3MF: {output}")
    print(f"Parts: {parts_dir}")
    print(f"Colors/objects: {len(meshes)}")
    if len(meshes) > 4:
        print("Note: this file uses more than 4 filament slots; one AMS can only hold 4 colors.")


if __name__ == "__main__":
    main()
