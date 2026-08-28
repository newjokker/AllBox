import unittest

from app import app, build_defines, parse_payload


class ShellWebAppTests(unittest.TestCase):
    def setUp(self):
        app.config.update(TESTING=True)
        self.client = app.test_client()

    def test_pages_and_health(self):
        self.assertEqual(self.client.get("/").status_code, 200)
        health = self.client.get("/health")
        self.assertEqual(health.status_code, 200)
        self.assertTrue(health.get_json()["source"])

    def test_invalid_geometry_is_rejected(self):
        response = self.client.post("/api/shell-stl", json={"fit_gap": 0.8, "wall": 0.8})
        self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/shell-stl", json={"pin_spacing": 18, "pin_slot_width": 4})
        self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/shell-stl", json={"typec_offset": 9})
        self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/shell-stl", json={"typec_cutouts": [{"face": "top"}]})
        self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/shell-stl", json={"button_plates": []})
        self.assertEqual(response.status_code, 400)

    def test_default_payload_builds_expected_matrices(self):
        with app.test_request_context("/api/shell-stl", method="POST", json={}):
            defines = build_defines(parse_payload())
        self.assertEqual(defines["part"], "both")
        self.assertEqual(len(defines["pin_row_matrix"]), 2)
        self.assertEqual(len(defines["button_matrix"]), 2)
        self.assertEqual(len(defines["typec_cutout_matrix"]), 1)
        self.assertEqual(len(defines["side_rect_cutout_matrix"]), 1)

    def test_multiple_typec_and_extension_cutouts_build_multiple_matrix_rows(self):
        payload = {
            "typec_cutouts": [
                {"face": "front", "offset": 0, "bottom": 1.5, "width": 11, "height": 4, "radius": 1.4},
                {"face": "left", "offset": 6, "bottom": 1.2, "width": 8, "height": 3, "radius": 1},
            ],
            "rect_cutouts": [
                {"face": "back", "offset": 0, "bottom": 1.6, "width": 16, "height": 3.5, "radius": .6},
                {"face": "right", "offset": -8, "bottom": 2, "width": 7, "height": 2.5, "radius": .5},
                {"face": "left", "offset": -8, "bottom": 2, "width": 7, "height": 2.5, "radius": .5},
            ],
        }
        with app.test_request_context("/api/shell-stl", method="POST", json=payload):
            defines = build_defines(parse_payload())
        self.assertEqual(len(defines["typec_cutout_matrix"]), 2)
        self.assertEqual(len(defines["side_rect_cutout_matrix"]), 3)

    def test_download_form_json_arrays_are_parsed(self):
        data = {
            "typec_cutouts": '[{"face":"front","offset":0,"bottom":1.5,"width":11,"height":4,"radius":1.4},{"face":"left","offset":4,"bottom":1.2,"width":7,"height":3,"radius":1}]',
            "rect_cutouts": '[{"face":"back","offset":0,"bottom":1.6,"width":16,"height":3.5,"radius":0.6},{"face":"right","offset":-8,"bottom":2,"width":7,"height":2.5,"radius":0.5}]',
            "button_plates": '[{"x":-3,"y":-4,"angle":180,"plunger_length":3.5,"flexure_length":8},{"x":0,"y":-3,"angle":180,"plunger_length":3.8,"flexure_length":10},{"x":3,"y":-4,"angle":180,"plunger_length":4,"flexure_length":12}]',
        }
        with app.test_request_context("/api/shell-stl", method="POST", data=data):
            defines = build_defines(parse_payload())
        self.assertEqual(len(defines["typec_cutout_matrix"]), 2)
        self.assertEqual(len(defines["side_rect_cutout_matrix"]), 2)
        self.assertEqual(len(defines["button_matrix"]), 3)

    def test_multiple_press_plates_build_multiple_button_matrix_rows(self):
        payload = {"button_plates": [
            {"x": -3, "y": -4, "angle": 180, "plunger_length": 3.2, "flexure_length": 8},
            {"x": 0, "y": -3, "angle": 180, "plunger_length": 3.8, "flexure_length": 10},
            {"x": 3, "y": -4, "angle": 180, "plunger_length": 4.2, "flexure_length": 12},
        ]}
        with app.test_request_context("/api/shell-stl", method="POST", json=payload):
            defines = build_defines(parse_payload())
        self.assertEqual(defines["button_matrix"], [
            [-3.0, -4.0, 180.0, 3.2, 8.0],
            [0.0, -3.0, 180.0, 3.8, 10.0],
            [3.0, -4.0, 180.0, 4.2, 12.0],
        ])

    def test_multiple_fix_posts_build_multiple_post_matrix_rows(self):
        payload = {"fix_posts": [
            {"x": 0, "y": 12, "diameter": 3, "base_diameter": 4.6, "length": 7.2},
            {"x": -6, "y": 5, "diameter": 2.5, "base_diameter": 4, "length": 5},
        ]}
        with app.test_request_context("/api/shell-stl", method="POST", json=payload):
            defines = build_defines(parse_payload())
        self.assertEqual(defines["lid_fix_post_matrix"], [
            [0.0, 12.0, 3.0, 7.2, 4.6, 1.2],
            [-6.0, 5.0, 2.5, 5.0, 4.0, 1.2],
        ])

    def test_legacy_post_fields_convert_to_fix_post(self):
        payload = {"post_enabled": True, "post_x": 0, "post_y": 12, "post_diameter": 3, "post_length": 7.2}
        with app.test_request_context("/api/shell-stl", method="POST", json=payload):
            params = parse_payload()
        self.assertEqual(params["fix_posts"], [
            {"x": 0.0, "y": 12.0, "diameter": 3.0, "base_diameter": 4.6, "length": 7.2},
        ])
        with app.test_request_context("/api/shell-stl", method="POST",
                                      json={"post_enabled": False, "post_x": 0}):
            self.assertEqual(parse_payload()["fix_posts"], [])

    def test_fix_post_base_must_not_be_smaller_than_shaft(self):
        payload = {"fix_posts": [{"x": 0, "y": 12, "diameter": 5, "base_diameter": 3, "length": 7.2}]}
        with app.test_request_context("/api/shell-stl", method="POST", json=payload):
            with self.assertRaises(ValueError):
                parse_payload()


if __name__ == "__main__":
    unittest.main()
