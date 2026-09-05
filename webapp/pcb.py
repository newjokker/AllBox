"""PCB configurator. Its defaults are read from the shared SCAD model."""
from __future__ import annotations

import hashlib
import io
import json
import math
import os
import re
import subprocess
from pathlib import Path

from flask import Blueprint, jsonify, render_template, request, send_file
from config_store import ConfigStore

SOURCE = Path(__file__).resolve().parents[1] / 'pcb_box.scad'

# (name, label, min, max, step). Defaults remain owned by pcb_box.scad.
GROUPS = [
    ('孔距与内壁距离', '直接从最外侧孔中心量到盒子内壁。盒外尺寸会自动加上壁厚，单位 mm。', [
        ('pcb_mount_hole_spacing_x', '横向孔中心距 X', 5, 180, .1),
        ('pcb_mount_hole_spacing_y', '纵向孔中心距 Y', 5, 140, .1),
        ('hole_wall_left', '最左孔 → 左内壁', 0, 140, .05),
        ('hole_wall_right', '最右孔 → 右内壁', 0, 140, .05),
        ('hole_wall_front', '最前孔 → 前内壁', 0, 140, .05),
        ('hole_wall_back', '最后孔 → 后内壁', 0, 140, .05),
    ]),
    ('板厚与器件高度', '自动模式按器件高度推算上盖。板下净空同时决定支撑柱高度。', [
        ('pcb_thickness', 'PCB 板厚', .5, 5, .1),
        ('lower_screw_post_height', '板下净空 / 支撑柱高', 3, 40, .1),
        ('component_height', '板上最高器件高度', 0, 80, .1),
        ('component_clearance', '器件顶部额外净空', .2, 10, .1),
        ('lower_box_height', '下盒高度（不含唇边）', 4, 100, .1),
        ('upper_box_height_manual', '手动上盖高度', 4, 100, .1),
    ]),
    ('结构与装配', '通常保留默认值；打印偏紧时可适当增加唇边配合间隙。', [
        ('wall_thickness', '侧壁厚度', 1, 4, .1),
        ('bottom_thickness', '底板厚度', .8, 4, .1),
        ('top_thickness', '盖板厚度', .8, 4, .1),
        ('corner_radius', '盒体圆角半径', 1, 15, .1),
        ('lip_height', '定位唇边高度', .5, 5, .1),
        ('lip_fit_gap', '唇边配合间隙', 0, .8, .05),
        ('pcb_fit_allowance', '夹板装配余量', 0, .5, .05),
        ('screw_pilot_depth', '下柱螺丝底孔深度', 2, 20, .1),
        ('open_distance', '打开预览时前后间距', 0, 100, 1),
        ('print_part_spacing', '打印平铺间距', 4, 40, 1),
    ]),
]
CHOICES = {
    'screw_size': ['m2', 'm2_5', 'm3', 'm4'],
    'screw_post_layout': ['spacing', 'custom'],
    'height_mode': ['auto', 'manual'],
    'part': ['both', 'base', 'lid'],
    'preview_mode': ['print', 'open', 'assembly'],
}
BOOLS = ['box_holes_enabled', 'screw_post_taper']
ARRAYS = ['screw_post_positions_custom', 'box_holes_custom']
FIELDS = [field for _, _, fields in GROUPS for field in fields]


def defaults():
    text = SOURCE.read_text(encoding='utf-8')
    values = {}
    for key in [f[0] for f in FIELDS] + list(CHOICES) + BOOLS + ARRAYS:
        match = re.search(r'^' + key + r'\s*=\s*(.*?);', text, re.M | re.S)
        if not match:
            raise RuntimeError(f'模型缺少参数 {key}')
        values[key] = json.loads(match[1])
    return values


def finite(raw, label, low, high):
    if isinstance(raw, bool):
        raise ValueError(f'{label}请输入数字')
    try:
        value = float(raw)
    except (TypeError, ValueError, OverflowError):
        raise ValueError(f'{label}请输入有效数字')
    if not math.isfinite(value) or not low <= value <= high:
        raise ValueError(f'{label}需在 {low:g}～{high:g} 之间')
    return round(value, 4)


def migrate_legacy(body):
    """Convert v1 margins/clearances and the special front hole without changing geometry."""
    body = dict(body)
    for side, old_edge, old_gap in [('left', 8.15, 2), ('right', 8.15, 2),
                                     ('front', 8.45, 23), ('back', 8.45, 2)]:
        edge, gap, target = f'pcb_hole_edge_{side}', f'pcb_clearance_{side}', f'hole_wall_{side}'
        if edge in body or gap in body:
            combined = finite(body.pop(edge, old_edge), '旧孔到板边距离', 0, 40) + finite(body.pop(gap, old_gap), '旧板外间隙', 0, 100)
            # Explicit v2 fields take precedence in mixed files; never sum twice.
            body.setdefault(target, round(combined, 4))
    front_keys = ['front_hole_enabled', 'front_hole_width', 'front_hole_height',
                  'front_hole_offset', 'front_hole_bottom']
    if any(key in body for key in front_keys):
        enabled = body.pop('front_hole_enabled', True)
        if not isinstance(enabled, bool):
            raise ValueError('旧前侧开口开关无效')
        width = finite(body.pop('front_hole_width', 8), '旧前侧开口宽度', .5, 100)
        height = finite(body.pop('front_hole_height', 4), '旧前侧开口高度', .5, 80)
        offset = finite(body.pop('front_hole_offset', -20), '旧前侧开口偏移', -150, 150)
        bottom = finite(body.pop('front_hole_bottom', 2), '旧前侧开口下沿高度', 0, 100)
        holes = body.get('box_holes_custom', [])
        if not isinstance(holes, list):
            raise ValueError('额外开孔必须是数组')
        body['box_holes_custom'] = ([['front', 'rect', offset, bottom+height/2, width, height]] if enabled else []) + holes
    return body


def normalize(body):
    if not isinstance(body, dict):
        raise ValueError('参数必须是一个 JSON 对象')
    body = migrate_legacy(body)
    p = defaults()
    unknown = set(body) - set(p)
    if unknown:
        raise ValueError('不支持的参数：' + ', '.join(sorted(unknown)))
    for key, label, lo, hi, _ in FIELDS:
        p[key] = finite(body.get(key, p[key]), label, lo, hi)
    for key, choices in CHOICES.items():
        value = body.get(key, p[key])
        if value not in choices:
            raise ValueError(f'{key} 选项无效')
        p[key] = value
    for key in BOOLS:
        value = body.get(key, p[key])
        if not isinstance(value, bool):
            raise ValueError(f'{key} 必须是开关值')
        p[key] = value
    for key in ARRAYS:
        value = body.get(key, p[key])
        if not isinstance(value, list) or len(value) > 32:
            raise ValueError('自定义孔位和开孔均最多支持 32 项')
        p[key] = value
    posts = []
    for point in p['screw_post_positions_custom']:
        if not isinstance(point, list) or len(point) != 2:
            raise ValueError('每个安装孔需填写 X、Y 两个坐标')
        posts.append([finite(v, '安装孔坐标', -200, 200) for v in point])
    if p['screw_post_layout'] == 'custom' and not posts:
        raise ValueError('请至少添加一个安装孔')
    p['screw_post_positions_custom'] = posts
    holes = []
    for h in p['box_holes_custom']:
        if not isinstance(h, list) or len(h) not in (5, 6):
            raise ValueError('开孔格式不正确')
        if h[0] not in ('front', 'back', 'left', 'right', 'top', 'bottom') or h[1] not in ('rect', 'circle'):
            raise ValueError('开孔所在面或形状无效')
        if len(h) != (5 if h[1] == 'circle' else 6):
            raise ValueError('开孔尺寸数量不正确')
        holes.append(h[:2] + [finite(v, '开孔位置', -300, 300) for v in h[2:4]]
                     + [finite(v, '开孔尺寸', .5, 150) for v in h[4:]])
    p['box_holes_custom'] = holes
    return p


def dimensions(p):
    sx, sy = p['pcb_mount_hole_spacing_x'], p['pcb_mount_hole_spacing_y']
    posts = p['screw_post_positions_custom'] if p['screw_post_layout'] == 'custom' else [
        [-sx/2, -sy/2], [sx/2, -sy/2], [-sx/2, sy/2], [sx/2, sy/2]]
    minx, maxx = min(x for x, y in posts), max(x for x, y in posts)
    miny, maxy = min(y for x, y in posts), max(y for x, y in posts)
    iw = maxx - minx + p['hole_wall_left'] + p['hole_wall_right']
    il = maxy - miny + p['hole_wall_front'] + p['hole_wall_back']
    cx = (minx - p['hole_wall_left'] + maxx + p['hole_wall_right']) / 2
    cy = (miny - p['hole_wall_front'] + maxy + p['hole_wall_back']) / 2
    positioned = [[x-cx, y-cy] for x,y in posts]
    total = p['bottom_thickness'] + p['lower_screw_post_height'] + p['pcb_thickness'] + p['component_height'] + p['component_clearance'] + p['top_thickness']
    upper = total - p['lower_box_height'] if p['height_mode'] == 'auto' else p['upper_box_height_manual']
    total = p['lower_box_height'] + upper
    above = total-p['bottom_thickness']-p['top_thickness']-p['lower_screw_post_height']-p['pcb_thickness']
    return dict(hole_span_x=maxx-minx, hole_span_y=maxy-miny, inner_width=iw, inner_length=il,
                box_width=iw+2*p['wall_thickness'], box_length=il+2*p['wall_thickness'],
                total_height=total, upper_box_height=upper, above_pcb=above,
                posts=positioned,
                upper_post_height=above-p['pcb_fit_allowance'])


def validate(p):
    d = dimensions(p)
    if min(d['inner_width'], d['inner_length']) <= 0:
        raise ValueError('盒内尺寸必须大于 0，请增加孔中心到内壁的距离')
    if p['lip_fit_gap'] >= p['wall_thickness']:
        raise ValueError('唇边配合间隙必须小于壁厚')
    if p['lower_box_height'] <= p['bottom_thickness']:
        raise ValueError('下盒高度必须大于底板厚度')
    if d['upper_box_height'] <= p['top_thickness'] + p['lip_height']:
        raise ValueError('上盖放不下定位唇边：请减小下盒/唇边高度，或增加器件顶部净空')
    if d['above_pcb'] + .001 < p['component_height'] + p['component_clearance']:
        raise ValueError('器件上方空间不足，请增加手动上盖高度')
    if d['upper_post_height'] <= 0:
        raise ValueError('夹板余量过大，上螺丝柱没有空间')
    if p['screw_pilot_depth'] > p['lower_screw_post_height']:
        raise ValueError('螺丝底孔深度不能超过支撑柱高度')
    if p['corner_radius'] >= min(d['box_width'], d['box_length']) / 2:
        raise ValueError('盒体圆角半径过大')
    foot = {'m2': 8.5, 'm2_5': 8.5, 'm3': 9, 'm4': 11.5}[p['screw_size']] / 2
    radius = max(p['corner_radius']-p['wall_thickness'], .02)
    for i, (x,y) in enumerate(d['posts']):
        # Signed distance to the rounded inner rectangle, including circular post foot.
        qx = abs(x) - (d['inner_width']/2-radius)
        qy = abs(y) - (d['inner_length']/2-radius)
        distance = math.hypot(max(qx,0), max(qy,0)) + min(max(qx,qy),0) - radius
        if distance + foot >= 0:
            raise ValueError(f'第 {i+1} 个柱脚碰到内壁/圆角，请增加该侧孔中心到内壁的距离')
        for other in d['posts'][:i]:
            if math.dist([x,y], other) < 2*foot:
                raise ValueError('安装柱脚重叠，请增大孔距或选择更小的螺丝')
    holes = list(p['box_holes_custom'])
    if p['box_holes_enabled']:
        for i, h in enumerate(holes, 1):
            face, shape, x, y, width = h[:5]
            height = width if shape == 'circle' else h[5]
            if face in ('top','bottom'):
                if abs(x)+width/2 >= d['inner_width']/2-radius or abs(y)+height/2 >= d['inner_length']/2-radius:
                    raise ValueError(f'开孔 {i} 超出顶/底板安全范围或靠近圆角')
                for px,py in d['posts']:
                    if abs(x-px) < width/2+foot and abs(y-py) < height/2+foot:
                        raise ValueError(f'开孔 {i} 与螺丝柱区域重叠')
            else:
                span = d['box_width'] if face in ('front','back') else d['box_length']
                if abs(x)+width/2 >= span/2-max(p['corner_radius'],p['wall_thickness']):
                    raise ValueError(f'开孔 {i} 超出侧壁平直区域，请减小宽度或横向偏移')
                if y-height/2 < p['bottom_thickness'] or y+height/2 >= p['lower_box_height']:
                    raise ValueError(f'开孔 {i} 的下沿必须不低于底板厚度，上沿必须低于下盒分型面')
    return d


def register_pcb(app, openscad, cache_dir, render_lock, serialize):
    bp = Blueprint('pcb', __name__)
    app.config.setdefault('PCB_CONFIG_DIR', os.environ.get('PCB_BOX_CONFIG_DIR',
        str(SOURCE.parent / 'data' / 'box-configs' / 'pcb-screw-box')))

    def store():
        return ConfigStore(app.config['PCB_CONFIG_DIR'], 'pcb-screw-box')

    @bp.get('/api/pcb/configs')
    def list_configs():
        return jsonify(store().list())

    @bp.post('/api/pcb/configs')
    def save_config():
        body = request.get_json(silent=True)
        try:
            if not isinstance(body, dict):
                raise ValueError('配置内容缺失')
            name = store().name(body.get('name'))
            params = normalize(body.get('config'))
            validate(params)
            return jsonify(store().save(name, params)), 201
        except ValueError as exc:
            return jsonify(error=str(exc)), 400
        except OSError:
            app.logger.exception('Cannot save PCB config')
            return jsonify(error='云端保存失败，请稍后重试；当前参数仍保留在表单中'), 503

    @bp.route('/api/pcb/configs/<name>', methods=['GET', 'DELETE'])
    def saved_config(name):
        try:
            if request.method == 'DELETE':
                return jsonify(store().delete(name))
            data = store().load(name)
            data['config'] = normalize(data['config'])
            validate(data['config'])
            return jsonify(data)
        except FileNotFoundError:
            return jsonify(error='配置不存在'), 404
        except ValueError as exc:
            return jsonify(error=str(exc)), 400
        except OSError:
            app.logger.exception('Cannot access PCB config')
            return jsonify(error='云端配置暂时不可用，请稍后重试'), 503


    @bp.get('/pcb')
    def page():
        return render_template('pcb.html', groups=GROUPS, defaults=defaults())

    @bp.get('/api/pcb/config')
    def config():
        p = normalize({})
        return jsonify(defaults=p, dimensions=validate(p))

    @bp.post('/api/pcb/validate')
    def check():
        try:
            p = normalize(request.get_json(silent=True))
            return jsonify(params=p, dimensions=validate(p))
        except ValueError as exc:
            return jsonify(error=str(exc)), 400

    @bp.post('/api/pcb/<kind>')
    def generate(kind):
        if kind not in ('stl', 'scad'):
            return jsonify(error='未知导出格式'), 404
        try:
            p = normalize(request.get_json(silent=True))
            validate(p)
        except ValueError as exc:
            return jsonify(error=str(exc)), 400
        # Downloads always use the printable layout, never the overlapping assembly view.
        if request.args.get('download') == '1':
            p['preview_mode'] = 'print'
        source = SOURCE.read_text(encoding='utf-8')
        if kind == 'scad':
            for key, value in p.items():
                source = re.sub(r'^' + key + r'\s*=\s*.*?;',
                                lambda m, k=key, v=value: f'{k} = {serialize(v)};', source,
                                count=1, flags=re.M | re.S)
            return send_file(io.BytesIO(source.encode()), mimetype='text/plain',
                             as_attachment=True, download_name='pcb_box.scad')
        if not openscad:
            return jsonify(error='服务器尚未安装 OpenSCAD'), 503
        digest = hashlib.sha256((source + json.dumps(p, sort_keys=True)).encode()).hexdigest()
        target = cache_dir / f'pcb-{digest}.stl'
        if not render_lock.acquire(timeout=2):
            return jsonify(error='模型生成器正在忙，请稍后重试'), 429
        try:
            if not target.exists():
                temp = target.with_suffix('.tmp.stl')
                cmd = [openscad, '-o', str(temp), '--export-format', 'binstl']
                for key, value in p.items():
                    cmd.extend(['-D', f'{key}={serialize(value)}'])
                cmd.append(str(SOURCE))
                try:
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=180,
                                            env={**os.environ, 'QT_QPA_PLATFORM': 'offscreen'})
                    if result.returncode or 'ERROR:' in result.stderr or not temp.exists() or temp.stat().st_size < 84:
                        return jsonify(error='模型生成失败：' + result.stderr[-1200:]), 422
                    temp.replace(target)
                finally:
                    temp.unlink(missing_ok=True)
        except subprocess.TimeoutExpired:
            return jsonify(error='生成超时，请减少开孔或简化模型后重试'), 504
        except OSError:
            app.logger.exception('PCB render failed')
            return jsonify(error='模型服务暂时不可用，请稍后重试'), 503
        finally:
            render_lock.release()
        response = send_file(target, mimetype='model/stl', as_attachment=True,
                             download_name=f"pcb_box_{p['part']}.stl")
        response.headers['Cache-Control'] = 'no-store'
        return response

    app.register_blueprint(bp)
