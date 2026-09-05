import json
import math
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from app import app
from pcb import normalize, validate, SOURCE


class PCBTests(unittest.TestCase):
    def setUp(self):
        app.config.update(TESTING=True)
        self.client = app.test_client()

    def test_page_and_default_measurements(self):
        self.assertEqual(self.client.get('/pcb').status_code, 200)
        response = self.client.get('/api/pcb/config').get_json()
        d = response['dimensions']
        self.assertAlmostEqual(d['inner_width'], 76.1)
        self.assertAlmostEqual(d['inner_length'], 61)
        self.assertAlmostEqual(d['box_width'], 80.1)
        self.assertAlmostEqual(d['box_length'], 65)
        self.assertAlmostEqual(d['total_height'], 16)
        self.assertEqual(response['defaults']['box_holes_custom'], [['front','rect',-20,4,8,4]])
        self.assertNotIn('pcb_width', d)
        html = self.client.get('/pcb').data.decode()
        for removed in ['板外预留空间', '前侧矩形开口', 'name="front_hole_enabled"']:
            self.assertNotIn(removed, html)
        self.assertIn('最前孔 → 前内壁', html)
        self.assertIn(b'/pcb', self.client.get('/').data)

    def test_asymmetric_wall_distances_set_exact_hole_positions(self):
        p = normalize({'hole_wall_left': 7, 'hole_wall_right': 13,
                       'hole_wall_front': 27, 'hole_wall_back': 9})
        d = validate(p)
        self.assertAlmostEqual(d['inner_width'], 75.8)
        self.assertAlmostEqual(min(x for x,y in d['posts']) + d['inner_width']/2, 7)
        self.assertAlmostEqual(d['inner_width']/2 - max(x for x,y in d['posts']), 13)
        self.assertAlmostEqual(min(y for x,y in d['posts']) + d['inner_length']/2, 27)
        self.assertAlmostEqual(d['inner_length']/2 - max(y for x,y in d['posts']), 9)

    def test_custom_origin_does_not_change_geometry(self):
        points = [[0,0], [55.8,0], [0,19.1], [55.8,19.1]]
        d = validate(normalize({'screw_post_layout':'custom','screw_post_positions_custom':points}))
        shifted = [[x+100,y-70] for x,y in points]
        e = validate(normalize({'screw_post_layout':'custom','screw_post_positions_custom':shifted}))
        for a,b in zip(d['posts'],e['posts']):
            for x,y in zip(a,b):self.assertAlmostEqual(x,y)

    def test_height_auto_and_manual_clearance(self):
        d = validate(normalize({'component_height':18}))
        self.assertAlmostEqual(d['total_height'],29.8)
        self.assertAlmostEqual(d['above_pcb'],19)
        with self.assertRaisesRegex(ValueError,'器件上方空间不足'):
            validate(normalize({'height_mode':'manual','component_height':18}))
        with self.assertRaisesRegex(ValueError,'定位唇边'):
            validate(normalize({'lower_box_height':12}))

    def test_invalid_input_is_400_before_render(self):
        cases = [[], None, {'pcb_thickness':True}, {'pcb_thickness':'NaN'},
                 {'pcb_thickness':float('inf')}, {'part':'../file'}, {'unknown':1},
                 {'screw_post_layout':'custom','screw_post_positions_custom':[]},
                 {'box_holes_custom':[['front','circle',0,4,5,5]]},
                 {'box_holes_custom':[['front','rect',0,4,'cube(99);',4]]},
                 {'screw_post_positions_custom':[[0,0]]*33}]
        for body in cases:
            with self.subTest(body=body):
                r=self.client.post('/api/pcb/stl',json=body)
                self.assertEqual(r.status_code,400)
                self.assertIn('error',r.get_json())

    def test_hole_bounds_and_disabled_holes(self):
        for hole in [['front','rect',-20,2,8,4], ['front','rect',-20,5.5,8,7], ['front','rect',100,4,8,4]]:
            body = {'box_holes_custom':[hole]}
            with self.assertRaises(ValueError):validate(normalize(body))
            validate(normalize({**body,'box_holes_enabled':False}))
        validate(normalize({'box_holes_custom':[['left','circle',0,4,3], ['top','rect',0,-10,8,4]]}))

    def test_holes_cannot_remove_post_support(self):
        with self.assertRaisesRegex(ValueError,'螺丝柱'):
            validate(normalize({'box_holes_custom':[['bottom','circle',27.9,20.05,6]]}))

    def test_posts_avoid_walls_corners_and_each_other(self):
        for body in [{'hole_wall_left':0},
                     {'hole_wall_left':5,'hole_wall_back':5,'corner_radius':15},
                     {'pcb_mount_hole_spacing_y':5},
                     {'screw_pilot_depth':10}]:
            with self.subTest(body=body):
                with self.assertRaises(ValueError):validate(normalize(body))

    def test_scad_download_is_standalone_and_printable(self):
        r=self.client.post('/api/pcb/scad?download=1',json={'preview_mode':'assembly','part':'lid','box_holes_custom':[['front','rect',0,4,8,4]]})
        self.assertEqual(r.status_code,200)
        source=r.data.decode()
        self.assertIn('preview_mode = "print";',source)
        self.assertIn('part = "lid";',source)
        self.assertIn('box_holes_custom = [["front","rect",0,4,8,4]];',source)
        self.assertNotIn('front_hole_',source)
        self.assertNotIn('pcb_clearance_',source)
        self.assertIn('module upper_lid()',source)
        self.assertNotIn('include <',source)

    def test_default_model_and_form_fields_stay_in_sync(self):
        from pcb import defaults
        with tempfile.TemporaryDirectory() as tmp:
            clone=Path(tmp)/'model.scad'
            clone.write_text(SOURCE.read_text().replace('hole_wall_left = 10.15;', 'hole_wall_left = 11.5;'))
            with patch('pcb.SOURCE',clone):
                self.assertEqual(defaults()['hole_wall_left'],11.5)
                self.assertEqual(self.client.get('/api/pcb/config').get_json()['defaults']['hole_wall_left'],11.5)

    def test_json_config_roundtrip(self):
        config=normalize({'hole_wall_front':31,'height_mode':'manual','upper_box_height_manual':10})
        r=self.client.post('/api/pcb/validate',json=json.loads(json.dumps(config)))
        self.assertEqual(r.status_code,200)
        self.assertEqual(r.get_json()['params'],config)

    def legacy_config(self):
        legacy = normalize({})
        for side,edge,gap in [('left',8.15,2),('right',8.15,2),('front',8.45,23),('back',8.45,2)]:
            legacy.pop(f'hole_wall_{side}')
            legacy[f'pcb_hole_edge_{side}'] = edge
            legacy[f'pcb_clearance_{side}'] = gap
        legacy.update(front_hole_enabled=True, front_hole_width=8, front_hole_height=4,
                      front_hole_offset=-20, front_hole_bottom=2, box_holes_custom=[])
        return legacy

    def test_legacy_draft_migrates_without_changing_geometry_or_duplicating_holes(self):
        migrated = normalize(self.legacy_config())
        self.assertEqual(migrated, normalize({}))
        self.assertEqual(normalize(migrated), migrated)
        response = self.client.post('/api/pcb/validate',json=self.legacy_config())
        self.assertEqual(response.status_code,200)
        self.assertEqual(response.get_json()['params'],migrated)

    def test_legacy_zero_gaps_from_screenshot_stay_zero(self):
        old = self.legacy_config()
        for side in ['left','right','front','back']:old[f'pcb_clearance_{side}'] = 0
        p = normalize(old)
        self.assertEqual([p[f'hole_wall_{side}'] for side in ['left','right','front','back']], [8.15,8.15,8.45,8.45])
        d = validate(p)
        self.assertAlmostEqual(d['inner_width'],72.1)
        self.assertAlmostEqual(d['inner_length'],36)
        self.assertAlmostEqual(d['box_width'],76.1)
        self.assertAlmostEqual(d['box_length'],40)

    def test_legacy_holes_keep_order_and_off_switches(self):
        old = self.legacy_config()
        extra = [['back','circle',0,4,3]]
        old['box_holes_custom'] = extra
        self.assertEqual(normalize(old)['box_holes_custom'], [['front','rect',-20,4,8,4]]+extra)
        old['front_hole_enabled'] = False
        self.assertEqual(normalize(old)['box_holes_custom'], extra)
        old['box_holes_enabled'] = False
        self.assertFalse(normalize(old)['box_holes_enabled'])

    def test_all_holes_can_be_removed(self):
        p = normalize({'box_holes_custom':[]})
        validate(p)
        self.assertEqual(p['box_holes_custom'],[])
        r=self.client.post('/api/pcb/scad',json=p)
        self.assertIn('box_holes_custom = [];',r.data.decode())

    def test_invalid_legacy_values_are_not_silently_discarded(self):
        for values in [{'pcb_clearance_front':-1}, {'pcb_clearance_left':'NaN'},
                       {'front_hole_enabled':'false'}, {'front_hole_height':None}]:
            with self.subTest(values=values):
                self.assertEqual(self.client.post('/api/pcb/validate',json=values).status_code,400)


if __name__=='__main__':unittest.main()
