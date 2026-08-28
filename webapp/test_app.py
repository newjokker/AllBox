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
        }
        with app.test_request_context("/api/shell-stl", method="POST", data=data):
            defines = build_defines(parse_payload())
        self.assertEqual(len(defines["typec_cutout_matrix"]), 2)
        self.assertEqual(len(defines["side_rect_cutout_matrix"]), 2)


if __name__ == "__main__":
    unittest.main()
