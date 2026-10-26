import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).parent.parent
spec = importlib.util.spec_from_file_location(
    "nvchecker_drift", ROOT / ".github" / "scripts" / "nvchecker_drift.py"
)
drift = importlib.util.module_from_spec(spec)
spec.loader.exec_module(drift)


class TestLoad(unittest.TestCase):
    def _write(self, data):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        path = Path(tmp.name) / "ver.json"
        path.write_text(json.dumps(data))
        return path

    def test_flat_map(self):
        self.assertEqual(drift.load(self._write({"a": "1"})), {"a": "1"})

    def test_v2_shape(self):
        data = {"version": 2, "data": {"a": {"version": "2", "url": "x"}}}
        self.assertEqual(drift.load(self._write(data)), {"a": "2"})


class TestFindDrift(unittest.TestCase):
    def test_reports_changed_and_untracked_sorted(self):
        old = {"b": "1", "a": "1", "same": "3"}
        new = {"b": "2", "a": "1.1", "same": "3", "new": "0.1"}
        self.assertEqual(
            drift.find_drift(old, new),
            [("a", "1", "1.1"), ("b", "1", "2"), ("new", "<untracked>", "0.1")],
        )

    def test_wanted_filters(self):
        old = {"a": "1", "b": "1"}
        new = {"a": "2", "b": "2"}
        self.assertEqual(drift.find_drift(old, new, {"b"}), [("b", "1", "2")])


class TestRender(unittest.TestCase):
    def test_no_drift(self):
        self.assertEqual(
            drift.render([]),
            "has_drift=false\ndrift<<NVDRIFT\nNVDRIFT\ndrift_tsv<<NVTSV\nNVTSV\n",
        )

    def test_forced_without_drift(self):
        self.assertTrue(drift.render([], forced=True).startswith("has_drift=true\n"))

    def test_drift_rows(self):
        out = drift.render([("a", "1", "2")])
        self.assertIn("\n- a: 1 -> 2\n", out)
        self.assertIn("\na\t1\t2\nNVTSV\n", out)


if __name__ == "__main__":
    unittest.main()
