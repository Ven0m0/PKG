import unittest
import sys
import io
import importlib.util
from pathlib import Path

# Import vp-dev.py as a module
ROOT = Path(__file__).parent.parent
spec = importlib.util.spec_from_file_location("vp_dev", ROOT / "tools" / "vp-dev.py")
vp_dev = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vp_dev)


class TestOutputUtils(unittest.TestCase):
    def test_colors(self):
        self.assertEqual(vp_dev.Colors.R, "\033[0;31m")
        self.assertEqual(vp_dev.Colors.G, "\033[0;32m")
        self.assertEqual(vp_dev.Colors.B, "\033[0;34m")
        self.assertEqual(vp_dev.Colors.Y, "\033[1;33m")
        self.assertEqual(vp_dev.Colors.N, "\033[0m")

    def test_info(self):
        captured_output = io.StringIO()
        sys.stdout = captured_output
        try:
            vp_dev.info("test message")
            self.assertEqual(
                captured_output.getvalue(),
                f"{vp_dev.Colors.B}→{vp_dev.Colors.N} test message\n"
            )
        finally:
            sys.stdout = sys.__stdout__

    def test_ok(self):
        captured_output = io.StringIO()
        sys.stdout = captured_output
        try:
            vp_dev.ok("test message")
            self.assertEqual(
                captured_output.getvalue(),
                f"{vp_dev.Colors.G}✓{vp_dev.Colors.N} test message\n"
            )
        finally:
            sys.stdout = sys.__stdout__

    def test_warn(self):
        captured_output = io.StringIO()
        sys.stdout = captured_output
        try:
            vp_dev.warn("test message")
            self.assertEqual(
                captured_output.getvalue(),
                f"{vp_dev.Colors.Y}⚠{vp_dev.Colors.N} test message\n"
            )
        finally:
            sys.stdout = sys.__stdout__

    def test_err(self):
        captured_output = io.StringIO()
        sys.stderr = captured_output
        try:
            vp_dev.err("error message")
            self.assertEqual(
                captured_output.getvalue(),
                f"{vp_dev.Colors.R}✗{vp_dev.Colors.N} error message\n"
            )
        finally:
            sys.stderr = sys.__stderr__


if __name__ == "__main__":
    unittest.main()
