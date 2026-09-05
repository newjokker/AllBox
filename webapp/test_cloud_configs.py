import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.parse import quote

import app as app_module
from app import app
from config_store import ConfigStore
from migrate_configs import migrate


class CloudConfigTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.esp = self.root / 'esp32-shell'
        self.esp.mkdir()
        self.pcb = self.root / 'pcb-screw-box'
        self.addCleanup(patch.stopall)
        patch.object(app_module, 'CONFIG_DIR', self.esp).start()
        patch.dict(app.config, PCB_CONFIG_DIR=str(self.pcb), TESTING=True).start()
        self.client = app.test_client()

    def test_cross_type_same_name_is_isolated(self):
        name='主控板安装盒'
        self.assertEqual(self.client.post('/api/configs',json={'name':name,'config':{}}).status_code,201)
        self.assertEqual(self.client.post('/api/pcb/configs',json={'name':name,'config':{'hole_wall_front':35}}).status_code,201)
        a=self.client.get('/api/configs/'+quote(name)).get_json()['config']
        b=self.client.get('/api/pcb/configs/'+quote(name)).get_json()['config']
        self.assertNotIn('hole_wall_front',a)
        self.assertEqual(b['hole_wall_front'],35)
        self.assertEqual(len(list(self.esp.glob('*.json'))),1)
        self.assertEqual(len(list(self.pcb.glob('*.json'))),1)
        self.assertEqual(self.client.get('/api/pcb/configs').get_json()[0]['name'],name)

    def test_overwrite_and_delete_preserve_history(self):
        for distance in [31,42]:
            response=self.client.post('/api/pcb/configs',json={'name':'测试配置','config':{'hole_wall_front':distance}})
            self.assertEqual(response.status_code,201)
        self.assertTrue(response.get_json()['backup'])
        backups=list((self.pcb/'history').glob('*.json'))
        self.assertEqual(len(backups),1)
        self.assertEqual(json.loads(backups[0].read_text())['config']['hole_wall_front'],31)
        self.assertEqual(self.client.delete('/api/pcb/configs/'+quote('测试配置')).status_code,200)
        self.assertEqual(self.client.get('/api/pcb/configs').get_json(),[])
        self.assertEqual(self.client.get('/api/pcb/configs/'+quote('测试配置')).status_code,404)
        self.assertEqual(len(list((self.pcb/'history').glob('*.json'))),2)

    def test_invalid_save_never_writes(self):
        for body in [None,[],{'name':'','config':{}},{'name':'../escape','config':{}},
                     {'name':'test','config':None},{'name':'test','config':{'hole_wall_left':0}}]:
            self.assertEqual(self.client.post('/api/pcb/configs',json=body).status_code,400)
        self.assertFalse(self.pcb.exists())

    def test_names_do_not_collide_and_new_client_can_load(self):
        for name in ['a b','a_b']:
            self.assertEqual(self.client.post('/api/pcb/configs',json={'name':name,'config':{}}).status_code,201)
        self.assertEqual(len(app.test_client().get('/api/pcb/configs').get_json()),2)
        self.assertEqual(app.test_client().get('/api/pcb/configs/a%20b').status_code,200)

    def test_save_migrates_legacy_pcb_parameters(self):
        r=self.client.post('/api/pcb/configs',json={'name':'旧版','config':{'pcb_clearance_front':0,'pcb_hole_edge_front':8.45}})
        self.assertEqual(r.status_code,201)
        data=self.client.get('/api/pcb/configs/'+quote('旧版')).get_json()
        self.assertEqual(data['config']['hole_wall_front'],8.45)
        self.assertNotIn('pcb_clearance_front',data['config'])
        self.assertEqual(data['box_type'],'pcb-screw-box')

    def test_write_failure_keeps_previous_file(self):
        store=ConfigStore(self.pcb,'pcb-screw-box');store.save('test',{'value':1})
        with patch.object(Path,'replace',side_effect=OSError('disk failure')):
            with self.assertRaises(OSError):store.save('test',{'value':2})
        self.assertEqual(store.load('test')['config']['value'],1)
        self.assertFalse(list(self.pcb.glob('*.tmp')))


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.old=self.root/'webapp/configs';(self.old/'history').mkdir(parents=True)
        (self.old/'用户配置.json').write_text('{"name":"user"}')
        (self.old/'history/previous.json').write_text('{"old":true}')
        self.dest=self.root/'data/box-configs/esp32-shell'

    def test_migration_keeps_bytes_history_and_seeds_only_absent(self):
        expected={str(p.relative_to(self.old)):p.read_bytes() for p in self.old.rglob('*.json')}
        presets=self.root/'webapp/presets/esp32-shell';presets.mkdir(parents=True)
        (presets/'用户配置.json').write_text('preset must not overwrite user')
        (presets/'new.json').write_text('{}')
        migrate(self.root)
        for name,raw in expected.items():self.assertEqual((self.dest/name).read_bytes(),raw)
        self.assertFalse(self.old.exists())
        self.assertEqual(len(list((self.root/'data/migration-history').iterdir())),1)
        migrate(self.root)
        self.assertEqual((self.dest/'用户配置.json').read_bytes(),expected['用户配置.json'])
        self.assertTrue((self.dest/'new.json').exists())
        self.assertTrue((self.root/'data/box-configs/pcb-screw-box').is_dir())

    def test_conflict_aborts_before_copying_and_preserves_old_data(self):
        self.dest.mkdir(parents=True);(self.dest/'用户配置.json').write_text('different newer data')
        with self.assertRaises(RuntimeError):migrate(self.root)
        self.assertTrue(self.old.exists())
        self.assertEqual((self.dest/'用户配置.json').read_text(),'different newer data')
        self.assertFalse((self.dest/'history/previous.json').exists())
