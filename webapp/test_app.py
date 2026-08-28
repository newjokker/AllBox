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

    def test_default_payload_builds_expected_matrices(self):
        with app.test_request_context("/api/shell-stl", method="POST", json={}):
            defines = build_defines(parse_payload())
        self.assertEqual(defines["part"], "both")
        self.assertEqual(len(defines["pin_row_matrix"]), 2)
        self.assertEqual(len(defines["button_matrix"]), 2)
        self.assertEqual(len(defines["typec_cutout_matrix"]), 1)
        self.assertEqual(len(defines["side_rect_cutout_matrix"]), 1)


if __name__ == "__main__":
    unittest.main()
