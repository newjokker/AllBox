import json
import tempfile
import unittest
from pathlib import Path
from urllib.parse import quote

import app as app_module
from app import app


class ConfigApiTests(unittest.TestCase):
    def setUp(self):
        app.config.update(TESTING=True)
        self._tmp = tempfile.TemporaryDirectory()
        app_module.CONFIG_DIR = Path(self._tmp.name)
        self.client = app.test_client()

    def tearDown(self):
        self._tmp.cleanup()

    def test_save_list_load_delete_roundtrip(self):
        payload = {
            "box_width": 20, "box_length": 45, "part": "base",
            "typec_cutouts": [{"face": "front", "offset": 0, "bottom": 1.5, "width": 11, "height": 4, "radius": 1.4}],
            "rect_cutouts": [{"face": "back", "offset": 0, "bottom": 1.6, "width": 16, "height": 3.5, "radius": .6}],
            "button_plates": [{"x": -2.25, "y": -4.18, "angle": 180, "plunger_length": 3.5, "flexure_length": 11.5},
                              {"x": 2.25, "y": -4.18, "angle": 180, "plunger_length": 3.5, "flexure_length": 11.5}],
        }
        url = quote("主控板A")
        save = self.client.post("/api/configs", json={"name": "主控板A", "config": payload})
        self.assertEqual(save.status_code, 201)
        self.assertEqual(save.get_json()["name"], "主控板A")

        listing = self.client.get("/api/configs")
        self.assertEqual(listing.status_code, 200)
        names = [entry["name"] for entry in listing.get_json()]
        self.assertIn("主控板A", names)

        loaded = self.client.get(f"/api/configs/{url}")
        self.assertEqual(loaded.status_code, 200)
        data = loaded.get_json()
        self.assertEqual(data["name"], "主控板A")
        self.assertEqual(data["config"]["box_width"], 20)
        self.assertEqual(len(data["config"]["button_plates"]), 2)

        self.assertEqual(self.client.delete(f"/api/configs/{url}").status_code, 200)
        self.assertEqual(self.client.get(f"/api/configs/{url}").status_code, 404)

    def test_save_requires_name_and_valid_config(self):
        self.assertEqual(self.client.post("/api/configs", json={"name": "", "config": {}}).status_code, 400)
        self.assertEqual(self.client.post("/api/configs", json={"name": "x", "config": None}).status_code, 400)
        resp = self.client.post("/api/configs", json={"name": "x", "config": {"fit_gap": 0.8, "wall": 0.8}})
        self.assertEqual(resp.status_code, 400)
        self.assertIn("配置无效", resp.get_json()["error"])

    def test_load_404_and_config_path_sanitization(self):
        self.assertEqual(self.client.get("/api/configs/不存在").status_code, 404)
        self.assertEqual(app_module._config_path("a/b c").name, "a_b_c.json")

    def test_list_skips_macos_sidecar_files(self):
        app_module.CONFIG_DIR.joinpath("测试.json").write_text(
            json.dumps({"name": "测试", "config": {}}), encoding="utf-8"
        )
        app_module.CONFIG_DIR.joinpath("._测试.json").write_bytes(b"\xb0\x00\xff binary")
        names = [entry["name"] for entry in self.client.get("/api/configs").get_json()]
        self.assertEqual(names, ["测试"])

    def test_config_can_be_loaded_by_display_name_when_filename_is_stable(self):
        app_module.CONFIG_DIR.joinpath("esp32_c6_weact_shell.json").write_text(
            json.dumps({"name": "ESP32-C6 WeAct", "config": {"box_width": 21.07, "box_length": 45.72}}),
            encoding="utf-8",
        )
        response = self.client.get(f"/api/configs/{quote('ESP32-C6 WeAct')}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["config"]["box_width"], 21.07)


if __name__ == "__main__":
    unittest.main()
