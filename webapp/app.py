from __future__ import annotations

import hashlib
import json
import math
import os
import re
import shutil
import subprocess
import threading
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, jsonify, render_template, request, send_file


ROOT = Path(__file__).resolve().parents[1]
SOURCE_SCAD = ROOT / "esp32_shell.scad"
CORE_SCAD = ROOT / "esp32_shell_core.scad"
CACHE_DIR = Path(os.environ.get("ESP32_SHELL_CACHE", "/tmp/esp32-shell-stl-cache"))
CACHE_DIR.mkdir(parents=True, exist_ok=True)
CONFIG_DIR = Path(os.environ.get("ESP32_SHELL_CONFIG_DIR", ROOT / "webapp" / "configs"))
CONFIG_DIR.mkdir(parents=True, exist_ok=True)
RENDER_LOCK = threading.Lock()


def find_openscad() -> str:
    configured = os.environ.get("OPENSCAD_BIN")
    candidates = [
        configured,
        "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
        shutil.which("openscad"),
        "/usr/local/bin/openscad-nightly",
        "/usr/bin/openscad",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).is_file() and os.access(candidate, os.X_OK):
            return candidate
    return ""


OPENSCAD = find_openscad()
app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 32 * 1024


def request_values() -> dict:
    if request.method == "GET":
        return request.args.to_dict()
    body = request.get_json(silent=True)
    return body if isinstance(body, dict) else request.form.to_dict()


def parse_payload(body: dict | None = None) -> dict:
    if body is None:
        body = request_values()

    def number(name: str, default: float, minimum: float, maximum: float, label: str) -> float:
        try:
            value = float(body.get(name, default))
        except (TypeError, ValueError):
            raise ValueError(f"{label}请输入有效数字")
        if not minimum <= value <= maximum:
            raise ValueError(f"{label}需要在 {minimum:g} 到 {maximum:g} mm 之间")
        return round(value, 4)

    def integer(name: str, default: int, minimum: int, maximum: int, label: str) -> int:
        value = number(name, default, minimum, maximum, label)
        if abs(value - round(value)) > 1e-8:
            raise ValueError(f"{label}请输入整数")
        return int(round(value))

    def boolean(name: str, default: bool) -> bool:
        raw = body.get(name, default)
        return raw if isinstance(raw, bool) else str(raw).lower() in ("1", "true", "yes", "on")

    def choice(name: str, default: str, choices: tuple[str, ...], label: str) -> str:
        value = str(body.get(name, default))
        if value not in choices:
            raise ValueError(f"{label}无效")
        return value

    def cutout_list(name: str, fallback: list[dict], label: str, *, typec: bool) -> list[dict]:
        raw = body.get(name)
        if raw is None:
            raw = fallback
        elif isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                raise ValueError(f"{label}配置不是有效的 JSON 数组")
        if not isinstance(raw, list):
            raise ValueError(f"{label}配置必须是数组")
        normalized = []
        for index, item in enumerate(raw, start=1):
            if not isinstance(item, dict):
                raise ValueError(f"{label}第 {index} 项格式无效")

            def item_number(key: str, default: float, minimum: float, maximum: float, item_label: str) -> float:
                try:
                    value = float(item.get(key, default))
                except (TypeError, ValueError):
                    raise ValueError(f"{label}第 {index} 项的{item_label}请输入有效数字")
                if not minimum <= value <= maximum:
                    raise ValueError(
                        f"{label}第 {index} 项的{item_label}需要在 {minimum:g} 到 {maximum:g} mm 之间"
                    )
                return round(value, 4)

            face = str(item.get("face", "front" if typec else "back"))
            allowed_faces = ("front", "back", "left", "right") if typec else (
                "front", "back", "left", "right", "top", "bottom"
            )
            if face not in allowed_faces:
                raise ValueError(f"{label}第 {index} 项的所在面无效")
            entry = {
                "face": face,
                "offset": item_number("offset", 0, -60, 60, "水平位置"),
                "bottom": item_number(
                    "bottom", 1.5 if typec else 1.6,
                    -70 if face in ("top", "bottom") else 0,
                    70 if face in ("top", "bottom") else 30,
                    "孔底高度" if face not in ("top", "bottom") else "Y 位置",
                ),
                "width": item_number("width", 11 if typec else 16.79, 3 if typec else 1, 90, "开口宽度"),
                "height": item_number("height", 4 if typec else 3.5, 1, 30, "开口高度"),
                "radius": item_number("radius", 1.4 if typec else 0.6, 0, 8, "圆角"),
            }
            normalized.append(entry)
        return normalized

    def button_list(fallback: list[dict]) -> list[dict]:
        raw = body.get("button_plates")
        if raw is None:
            raw = fallback
        elif isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                raise ValueError("按压板配置不是有效的 JSON 数组")
        if not isinstance(raw, list):
            raise ValueError("按压板配置必须是数组")
        normalized = []
        for index, item in enumerate(raw, start=1):
            if not isinstance(item, dict):
                raise ValueError(f"按压板第 {index} 项格式无效")

            def item_number(key: str, default: float, minimum: float, maximum: float, label: str) -> float:
                try:
                    value = float(item.get(key, default))
                except (TypeError, ValueError):
                    raise ValueError(f"按压板第 {index} 项的{label}请输入有效数字")
                if not minimum <= value <= maximum:
                    raise ValueError(
                        f"按压板第 {index} 项的{label}需要在 {minimum:g} 到 {maximum:g} 之间"
                    )
                return round(value, 4)

            if item.get("front_distance") is not None:
                front_distance = item_number(
                    "front_distance", 15.5, 0, 150, "距 front 前端内壁距离"
                )
                y_position = round(-params["box_length"] / 2 + front_distance, 4)
            else:
                y_position = item_number("y", -4.18, -70, 70, "Y 位置")
                front_distance = round(y_position + params["box_length"] / 2, 4)

            normalized.append({
                "x": item_number("x", 0, -45, 45, "X 位置"),
                "front_distance": front_distance,
                "y": y_position,
                "angle": item_number("angle", 180, -360, 360, "弹片方向"),
                "plunger_length": item_number("plunger_length", 3.5, 0.2, 15, "触点长度"),
                "flexure_length": item_number("flexure_length", 11.5, 2.1, 40, "弹片长度"),
            })
        return normalized

    def post_list(fallback: list[dict]) -> list[dict]:
        legacy_keys = ("post_enabled", "post_x", "post_y", "post_diameter", "post_length")
        if body.get("fix_posts") is None and any(key in body for key in legacy_keys):
            if not boolean("post_enabled", True):
                return []
            legacy_d = number("post_diameter", 3, 1, 12, "固定柱直径")
            raw = [{
                "x": number("post_x", 0, -45, 45, "固定柱 X"),
                "y": number("post_y", 12, -70, 70, "固定柱 Y"),
                "diameter": legacy_d,
                "base_diameter": legacy_d + 1.6,
                "length": number("post_length", 7.2, 1.3, 25, "固定柱长度"),
            }]
        else:
            raw = body.get("fix_posts", fallback)
        if isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                raise ValueError("固定柱配置不是有效的 JSON 数组")
        if not isinstance(raw, list):
            raise ValueError("固定柱配置必须是数组")
        normalized = []
        for index, item in enumerate(raw, start=1):
            if not isinstance(item, dict):
                raise ValueError(f"固定柱第 {index} 项格式无效")

            def item_number(key: str, default: float, minimum: float, maximum: float, label: str) -> float:
                try:
                    value = float(item.get(key, default))
                except (TypeError, ValueError):
                    raise ValueError(f"固定柱第 {index} 项的{label}请输入有效数字")
                if not minimum <= value <= maximum:
                    raise ValueError(
                        f"固定柱第 {index} 项的{label}需要在 {minimum:g} 到 {maximum:g} mm 之间"
                    )
                return round(value, 4)

            if item.get("front_distance") is not None:
                front_distance = item_number(
                    "front_distance", 31.68, 0, 160, "距 front 前端内壁距离"
                )
                y_position = round(-params["box_length"] / 2 + front_distance, 4)
            else:
                y_position = item_number("y", 12, -70, 70, "Y 位置")
                front_distance = round(y_position + params["box_length"] / 2, 4)

            normalized.append({
                "x": item_number("x", 0, -45, 45, "X 位置"),
                "front_distance": front_distance,
                "y": y_position,
                "diameter": item_number("diameter", 3, 1, 12, "柱体直径"),
                "base_diameter": item_number("base_diameter", 4.6, 1, 20, "底座直径"),
                "length": item_number("length", 7.2, 1.3, 25, "向下长度"),
            })
        return normalized

    def snap_list(fallback: list[dict]) -> list[dict]:
        raw = body.get("snap_bumps", fallback)
        if isinstance(raw, str):
            try:
                raw = json.loads(raw)
            except json.JSONDecodeError:
                raise ValueError("卡扣配置不是有效的 JSON 数组")
        if not isinstance(raw, list):
            raise ValueError("卡扣配置必须是数组")
        normalized = []
        for index, item in enumerate(raw, start=1):
            if not isinstance(item, dict):
                raise ValueError(f"卡扣第 {index} 项格式无效")
            face = str(item.get("face", "right"))
            if face not in ("front", "back", "left", "right"):
                raise ValueError(f"卡扣第 {index} 项的所在面无效")
            try:
                offset = float(item.get("offset", 0))
                length = float(item.get("length", 5))
            except (TypeError, ValueError):
                raise ValueError(f"卡扣第 {index} 项请输入有效数字")
            if not -70 <= offset <= 70 or not 0.5 <= length <= 50:
                raise ValueError(f"卡扣第 {index} 项超出允许范围")
            normalized.append({"face": face, "offset": round(offset, 4), "length": round(length, 4)})
        return normalized

    board_clearance = number("board_clearance", 0.5, 0.01, 10, "PCB 板边余量")
    legacy_box_width = number("box_width", 18.79, 5, 110, "内部净宽")
    legacy_box_length = number("box_length", 39.36, 5, 160, "内部净长")
    pcb_width = number("pcb_width", legacy_box_width - board_clearance, 1, 100, "PCB 宽度")
    pcb_length = number("pcb_length", legacy_box_length - board_clearance, 1, 150, "PCB 长度")

    params = {
        "part": choice("part", "both", ("both", "base", "lid"), "导出零件"),
        "layout": choice("layout", "print", ("print", "assembly", "open"), "显示方式"),
        "pcb_width": pcb_width,
        "pcb_length": pcb_length,
        "board_clearance": board_clearance,
        "box_width": round(pcb_width + board_clearance, 4),
        "box_length": round(pcb_length + board_clearance, 4),
        "base_height": number("base_height", 6, 2, 40, "下盒净高"),
        "lid_height": number("lid_height", 4, 2.2, 30, "上盖高度"),
        "wall": number("wall", 2, 1, 5, "壁厚"),
        "bottom_t": number("bottom_t", 1.6, 0.8, 5, "底板厚度"),
        "top_t": number("top_t", 1.6, 0.8, 5, "顶板厚度"),
        "corner_r": number("corner_r", 2, 0.5, 8, "外壳圆角"),
        "fit_gap": number("fit_gap", 0.08, 0.02, 0.8, "配合间隙"),
        "typec_enabled": boolean("typec_enabled", False),
        "typec_face": choice("typec_face", "front", ("front", "back", "left", "right"), "Type-C 所在面"),
        "typec_offset": number("typec_offset", 0, -60, 60, "Type-C 水平位置"),
        "typec_bottom": number("typec_bottom", 1.5, 0, 30, "Type-C 底部高度"),
        "typec_width": number("typec_width", 11, 3, 30, "Type-C 开口宽度"),
        "typec_height": number("typec_height", 4, 1, 15, "Type-C 开口高度"),
        "typec_radius": number("typec_radius", 1.4, 0, 5, "Type-C 圆角"),
        "rear_enabled": boolean("rear_enabled", False),
        "rear_face": choice("rear_face", "back", ("front", "back", "left", "right"), "扩展出口所在面"),
        "rear_offset": number("rear_offset", 0, -60, 60, "扩展出口水平位置"),
        "rear_bottom": number("rear_bottom", 1.6, 0, 30, "扩展出口底部高度"),
        "rear_width": number("rear_width", 16.79, 1, 90, "扩展出口宽度"),
        "rear_height": number("rear_height", 3.5, 1, 30, "扩展出口高度"),
        "rear_radius": number("rear_radius", 0.6, 0, 5, "扩展出口圆角"),
        # 旧配置没有 pin_enabled；只要它保存过排针参数，就继续按开启处理。
        "pin_enabled": boolean(
            "pin_enabled", any(key in body for key in ("pin_spacing", "pin_length", "pin_slot_width", "pin_y_offset"))
        ),
        "pin_spacing": number("pin_spacing", 15.2, 2, 60, "两排排针间距"),
        "pin_length": number("pin_length", 32, 4, 120, "排针槽长度"),
        "pin_slot_width": number("pin_slot_width", 3, 1, 8, "排针槽宽度"),
        "pin_y_offset": number("pin_y_offset", 0.1, -30, 30, "排针纵向偏移"),
        "button_spacing": number("button_spacing", 4.5, 1, 30, "按键间距"),
        "button_y": number("button_y", -4.18, -70, 70, "按键 Y 位置"),
        "button_angle": number("button_angle", 180, -360, 360, "弹片方向"),
        "button_plunger_length": number("button_plunger_length", 3.5, 0.2, 15, "触点长度"),
        "vent_enabled": boolean("vent_enabled", False),
        "vent_auto_fill": boolean("vent_auto_fill", False),
        "vent_center_x": number("vent_center_x", 0, -50, 50, "散热区 X"),
        "vent_center_y": number("vent_center_y", 10, -70, 70, "散热区 Y"),
        "vent_rows": integer("vent_rows", 4, 1, 30, "蜂窝行数"),
        "vent_columns": integer("vent_columns", 5, 1, 30, "蜂窝列数"),
        "vent_hole_diameter": number("vent_hole_diameter", 3.3, 1, 10, "蜂窝孔径"),
        "vent_pitch_x": number("vent_pitch_x", 4, 1, 15, "蜂窝横向间距"),
        "vent_pitch_y": number("vent_pitch_y", 4.8, 1, 15, "蜂窝纵向间距"),
    }

    params["typec_cutouts"] = cutout_list(
        "typec_cutouts",
        [{
            "face": params["typec_face"], "offset": params["typec_offset"],
            "bottom": params["typec_bottom"], "width": params["typec_width"],
            "height": params["typec_height"], "radius": params["typec_radius"],
        }] if params["typec_enabled"] else [],
        "Type-C 开口",
        typec=True,
    )
    params["rect_cutouts"] = cutout_list(
        "rect_cutouts",
        [{
            "face": params["rear_face"], "offset": params["rear_offset"],
            "bottom": params["rear_bottom"], "width": params["rear_width"],
            "height": params["rear_height"], "radius": params["rear_radius"],
        }] if params["rear_enabled"] else [],
        "扩展出口",
        typec=False,
    )
    params["button_plates"] = button_list([])
    params["fix_posts"] = post_list([])
    params["snap_bumps"] = snap_list([])

    if params["fit_gap"] >= params["wall"]:
        raise ValueError("配合间隙必须小于壁厚")
    if params["corner_r"] > min(params["box_width"], params["box_length"]) / 2:
        raise ValueError("外壳圆角过大")
    if params["vent_pitch_x"] < params["vent_hole_diameter"] or params["vent_pitch_y"] < params["vent_hole_diameter"]:
        raise ValueError("蜂窝孔中心间距不能小于孔径")
    for index, post in enumerate(params["fix_posts"], start=1):
        if post["base_diameter"] < post["diameter"]:
            raise ValueError(f"固定柱第 {index} 项的底座直径不能小于柱体直径")
        if abs(post["x"]) + post["base_diameter"] / 2 >= params["box_width"] / 2:
            raise ValueError(f"固定柱第 {index} 项的 X 位置超出盒内范围")
        if abs(post["y"]) + post["base_diameter"] / 2 >= params["box_length"] / 2:
            raise ValueError(f"固定柱第 {index} 项的 Y 位置超出盒内范围")
    for index, snap in enumerate(params["snap_bumps"], start=1):
        face_span = (
            params["box_length"] if snap["face"] in ("left", "right") else params["box_width"]
        ) + 2 * params["wall"]
        if abs(snap["offset"]) + snap["length"] / 2 > face_span / 2:
            raise ValueError(f"卡扣第 {index} 项超出所在侧壁范围")
    if params["pin_enabled"] and params["pin_spacing"] + params["pin_slot_width"] > params["box_width"]:
        raise ValueError("排针行间距加槽宽超过盒内净宽")
    if params["pin_enabled"] and params["pin_length"] > params["box_length"]:
        raise ValueError("排针槽长度不能超过盒内净长")
    for index, button in enumerate(params["button_plates"], start=1):
        if abs(button["x"]) + 2 > params["box_width"] / 2 or abs(button["y"]) + 2 > params["box_length"] / 2:
            raise ValueError(f"按压板第 {index} 项的按压头超出上盖")
        angle_radians = math.radians(button["angle"])
        flexure_end_x = button["x"] - math.sin(angle_radians) * button["flexure_length"]
        flexure_end_y = button["y"] + math.cos(angle_radians) * button["flexure_length"]
        if abs(flexure_end_x) + 2 >= params["box_width"] / 2 or abs(flexure_end_y) + 2 >= params["box_length"] / 2:
            raise ValueError(f"按压板第 {index} 项的弹片末端超出上盖，请调整位置或方向")
    for entries, label, must_stay_below_lip in (
        (params["typec_cutouts"], "Type-C 开口", True),
        (params["rect_cutouts"], "扩展出口", False),
    ):
        for index, entry in enumerate(entries, start=1):
            if entry["radius"] >= min(entry["width"], entry["height"]) / 2:
                raise ValueError(f"{label}第 {index} 项的圆角必须小于开口短边的一半")
            if must_stay_below_lip and entry["bottom"] + entry["height"] >= params["base_height"]:
                raise ValueError(f"{label}第 {index} 项会侵入卡扣唇边，请降低或缩小开口")
            if entry["face"] in ("top", "bottom"):
                if abs(entry["offset"]) + entry["width"] / 2 > params["box_width"] / 2 + params["wall"] or \
                   abs(entry["bottom"]) + entry["height"] / 2 > params["box_length"] / 2 + params["wall"]:
                    raise ValueError(f"{label}第 {index} 项超出顶面或底面范围")
            else:
                face_span = params["box_width"] if entry["face"] in ("front", "back") else params["box_length"]
                if abs(entry["offset"]) + entry["width"] / 2 > face_span / 2:
                    raise ValueError(f"{label}第 {index} 项超出所在侧壁范围")
    return params


def scad_value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (list, tuple)):
        return "[" + ",".join(scad_value(item) for item in value) + "]"
    return f"{value:g}" if isinstance(value, float) else str(value)


def build_defines(params: dict) -> dict:
    half_pin_spacing = params["pin_spacing"] / 2
    pin_y = round(-(params["box_length"] - params["pin_length"]) / 2 + params["pin_y_offset"], 4)
    typec_matrix = [[
        entry["face"], entry["offset"], entry["bottom"], entry["width"],
        entry["height"], entry["radius"], max(params["wall"] + 1, 4),
    ] for entry in params["typec_cutouts"]]
    rear_matrix = [[
        entry["face"], entry["offset"], entry["bottom"], entry["width"],
        entry["height"], entry["radius"],
    ] for entry in params["rect_cutouts"]]
    post_matrix = [[
        post["x"], post["y"], post["diameter"], post["length"],
        post["base_diameter"], 1.2,
    ] for post in params["fix_posts"]]
    return {
        "part": params["part"], "layout": params["layout"],
        "pcb_size": [params["pcb_width"], params["pcb_length"], 1.6],
        "box_width": params["box_width"], "box_length": params["box_length"],
        "base_height": params["base_height"], "lid_height": params["lid_height"],
        "wall": params["wall"], "bottom_t": params["bottom_t"], "top_t": params["top_t"],
        "corner_r": params["corner_r"], "fit_gap": params["fit_gap"],
        "typec_enabled": len(typec_matrix) > 0, "typec_cutout_matrix": typec_matrix,
        "side_rect_cutout_matrix": rear_matrix,
        "side_rect_cutout_depth": max(params["wall"] + 1, params["bottom_t"] + 1, params["top_t"] + 1, 4),
        "pin_length": params["pin_length"], "pin_slot_width": params["pin_slot_width"],
        "pin_row_matrix": (
            [[-half_pin_spacing, pin_y, params["pin_length"]], [half_pin_spacing, pin_y, params["pin_length"]]]
            if params["pin_enabled"] else []
        ),
        "snap_bump_matrix": [[snap["face"], snap["offset"], snap["length"]] for snap in params["snap_bumps"]],
        "button_matrix": [[
            button["x"], button["y"], button["angle"], button["plunger_length"],
            button["flexure_length"],
        ] for button in params["button_plates"]],
        "vent_enabled": params["vent_enabled"], "vent_auto_fill": params["vent_auto_fill"],
        "vent_center": [params["vent_center_x"], params["vent_center_y"]],
        "vent_rows": params["vent_rows"], "vent_columns": params["vent_columns"],
        "vent_hole_diameter": params["vent_hole_diameter"],
        "vent_pitch": [params["vent_pitch_x"], params["vent_pitch_y"]],
        "lid_fix_post_matrix": post_matrix,
    }


def render_stl(output_path: Path, defines: dict) -> None:
    command = [OPENSCAD, "-o", str(output_path), "--export-format", "binstl"]
    for name, value in defines.items():
        command.extend(["-D", f"{name}={scad_value(value)}"])
    command.append(str(SOURCE_SCAD))
    openscad_path_parts = []
    bundled_libraries = ROOT / "third_party"
    if bundled_libraries.is_dir():
        openscad_path_parts.append(str(bundled_libraries))
    if os.environ.get("OPENSCADPATH"):
        openscad_path_parts.append(os.environ["OPENSCADPATH"])
    render_env = dict(os.environ)
    if openscad_path_parts:
        render_env["OPENSCADPATH"] = os.pathsep.join(openscad_path_parts)
    completed = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, timeout=240,
        env=render_env,
    )
    if completed.returncode != 0 or not output_path.exists() or output_path.stat().st_size < 84:
        output_path.unlink(missing_ok=True)
        message = (completed.stderr or completed.stdout or "OpenSCAD 未生成 STL").strip()
        raise RuntimeError(message[-1800:])


@app.get("/")
def index():
    return render_template("index.html")


@app.route("/api/shell-stl", methods=["GET", "POST"])
def shell_stl():
    try:
        params = parse_payload()
        body = request_values()
        as_download = str(body.get("download", "0")).lower() in ("1", "true", "yes", "on")
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    if not OPENSCAD:
        return jsonify({"error": "服务器尚未安装 OpenSCAD"}), 503
    if not SOURCE_SCAD.exists() or not CORE_SCAD.exists():
        return jsonify({"error": "服务器缺少 ESP32 壳体 SCAD 源文件"}), 503

    defines = build_defines(params)
    source_hash = hashlib.sha256(SOURCE_SCAD.read_bytes() + CORE_SCAD.read_bytes()).hexdigest()
    cache_input = json.dumps({"source": source_hash, "defines": defines}, ensure_ascii=False, sort_keys=True)
    cache_key = hashlib.sha256(cache_input.encode("utf-8")).hexdigest()
    stl_path = CACHE_DIR / f"esp32-shell-{cache_key}.stl"
    try:
        with RENDER_LOCK:
            if not stl_path.exists():
                render_stl(stl_path, defines)
    except (RuntimeError, subprocess.TimeoutExpired) as exc:
        return jsonify({"error": str(exc)}), 500

    filename = f"esp32_shell_{params['part']}_{params['box_width']:g}x{params['box_length']:g}.stl"
    response = send_file(stl_path, mimetype="model/stl", as_attachment=as_download, download_name=filename)
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Shell-Part"] = params["part"]
    return response


@app.get("/api/config")
def config():
    return jsonify({"source": SOURCE_SCAD.name, "openscad": OPENSCAD or None})


def _config_path(name: str) -> Path:
    safe = re.sub(r"[^\w\-]+", "_", name).strip("._") or "config"
    return CONFIG_DIR / f"{safe}.json"


def _find_config_path(name: str) -> Path:
    """Resolve saved configs by filename or by their user-facing JSON name."""
    direct = _config_path(name)
    if direct.exists():
        return direct
    for path in CONFIG_DIR.glob("*.json"):
        if path.name.startswith("._"):
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError):
            continue
        if str(data.get("name", "")) == name:
            return path
    return direct


def _backup_config(path: Path) -> Path | None:
    """Keep the previous JSON before an existing configuration is replaced."""
    if not path.exists():
        return None
    history_dir = CONFIG_DIR / "history"
    history_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    backup_path = history_dir / f"{path.stem}__{timestamp}.json"
    shutil.copy2(path, backup_path)
    return backup_path


@app.get("/api/configs")
def list_configs():
    entries = []
    for path in sorted(CONFIG_DIR.glob("*.json")):
        if path.name.startswith("._"):  # macOS resource-fork sidecar
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError):
            continue
        cfg = data.get("config")
        meta = {
            "name": str(data.get("name", path.stem)),
            "saved_at": data.get("saved_at"),
        }
        if isinstance(cfg, dict):
            for key in (
                "pcb_width", "pcb_length", "board_clearance", "box_width", "box_length",
                "part", "layout", "base_height", "lid_height",
            ):
                meta[key] = cfg.get(key)
        entries.append(meta)
    return jsonify(entries)


@app.post("/api/configs")
def save_config():
    body = request.get_json(silent=True) or {}
    name = str(body.get("name", "")).strip()
    if not name:
        return jsonify({"error": "请先输入配置名称"}), 400
    if len(name) > 60:
        return jsonify({"error": "配置名称过长"}), 400
    config = body.get("config")
    if not isinstance(config, dict):
        return jsonify({"error": "配置内容缺失"}), 400
    try:
        validated = parse_payload(config)
    except ValueError as exc:
        return jsonify({"error": f"配置无效：{exc}"}), 400
    path = _find_config_path(name)
    backup_path = _backup_config(path)
    data = {
        "name": name,
        "saved_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "config": validated,
    }
    temporary_path = path.with_suffix(f".{os.getpid()}.{threading.get_ident()}.tmp")
    try:
        temporary_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        temporary_path.replace(path)
    finally:
        temporary_path.unlink(missing_ok=True)
    return jsonify({
        "name": name,
        "saved_at": data["saved_at"],
        "backup": backup_path.name if backup_path else None,
    }), 201


@app.get("/api/configs/<name>")
def load_config(name):
    path = _find_config_path(name)
    if not path.exists():
        return jsonify({"error": "配置不存在"}), 404
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return jsonify({"error": "配置文件无法读取"}), 500
    cfg = data.get("config")
    if not isinstance(cfg, dict):
        return jsonify({"error": "配置文件内容无效"}), 500
    try:
        cfg = parse_payload(cfg)
    except ValueError as exc:
        return jsonify({"error": f"配置已过期：{exc}"}), 400
    return jsonify({"name": str(data.get("name", path.stem)), "saved_at": data.get("saved_at"), "config": cfg})


@app.delete("/api/configs/<name>")
def delete_config(name):
    path = _find_config_path(name)
    if not path.exists():
        return jsonify({"error": "配置不存在"}), 404
    path.unlink()
    return jsonify({"ok": True})


@app.get("/health")
def health():
    return {"status": "ok", "openscad": bool(OPENSCAD), "source": SOURCE_SCAD.exists() and CORE_SCAD.exists()}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "55505")))
