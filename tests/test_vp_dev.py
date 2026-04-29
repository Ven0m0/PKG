import unittest
from unittest.mock import patch, MagicMock
import sys
import os
import importlib.util
from pathlib import Path
import tempfile
import time

# Dynamically import vp-dev.py
spec = importlib.util.spec_from_file_location("vp_dev", os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "vp-dev.py"))
vp_dev = importlib.util.module_from_spec(spec)
sys.modules["vp_dev"] = vp_dev
spec.loader.exec_module(vp_dev)

class TestVpDev(unittest.TestCase):
    def setUp(self):
        # Create a mock App instance
        self.app = vp_dev.VpDev()
        self.app.root = Path('/mock/root')
        self.app.files_cache = None

    def test_parse_srcinfo_missing_files(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            # Both missing
            self.assertIsNone(self.app._parse_srcinfo(d))

            # SRCINFO missing, PKGBUILD exists
            (d / "PKGBUILD").touch()
            self.assertIsNone(self.app._parse_srcinfo(d))

            # SRCINFO exists, PKGBUILD missing
            (d / "PKGBUILD").unlink()
            (d / ".SRCINFO").touch()
            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_older_srcinfo(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"

            si.touch()
            # Ensure PKGBUILD is newer
            old_time = time.time() - 10
            os.utime(si, (old_time, old_time))
            pb.touch()

            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_successful(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"

            pb.touch()
            # Ensure SRCINFO is newer
            old_time = time.time() - 10
            os.utime(d / "PKGBUILD", (old_time, old_time))

            si_content = """pkgbase = mypkg
	pkgdesc = My cool package
	pkgver = 1.0.0
	pkgrel = 2
	url = https://example.com
	arch = x86_64
	license = MIT
	makedepends = cmake
	source = https://example.com/source.tar.gz

pkgname = mypkg
	depends = glibc
"""
            si.write_text(si_content)

            with patch('subprocess.run') as mock_run:
                mock_run_result = MagicMock()
                mock_run_result.returncode = 0
                mock_run_result.stdout = "PKGBUILD\nsome_patch.patch\nanother_file.txt\n"
                mock_run.return_value = mock_run_result

                result = self.app._parse_srcinfo(d)

                self.assertIsNotNone(result)
                self.assertEqual(result["name"], "mypkg")
                self.assertEqual(result["version"], "1.0.0-2")
                self.assertEqual(result["description"], "My cool package")
                self.assertEqual(result["url"], "https://example.com")
                self.assertEqual(result["files"], ["another_file.txt", "some_patch.patch"])

                mock_run.assert_called_once()

    def test_parse_srcinfo_files_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"

            pb.touch()
            # Ensure SRCINFO is newer
            old_time = time.time() - 10
            os.utime(d / "PKGBUILD", (old_time, old_time))

            si_content = """pkgbase = mypkg
	pkgdesc = My cool package
	pkgver = 1.0.0
	pkgrel = 2

pkgname = mypkg
"""
            si.write_text(si_content)

            self.app.files_cache = {d: ["PKGBUILD", "cached_file.txt", "z_file.txt"]}

            result = self.app._parse_srcinfo(d)
            self.assertIsNotNone(result)
            self.assertEqual(result["files"], ["cached_file.txt", "z_file.txt"])

    def test_parse_srcinfo_incomplete(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"

            pb.touch()
            # Ensure SRCINFO is newer
            old_time = time.time() - 10
            os.utime(d / "PKGBUILD", (old_time, old_time))

            si_content = """pkgbase = mypkg
	pkgdesc = My cool package
	pkgver = 1.0.0

pkgname = mypkg
""" # Missing pkgrel
            si.write_text(si_content)

            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_multiple_packages(self):
         with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"

            pb.touch()
            # Ensure SRCINFO is newer
            old_time = time.time() - 10
            os.utime(d / "PKGBUILD", (old_time, old_time))

            si_content = """pkgbase = mypkg
	pkgdesc = Base package
	pkgver = 1.0.0
	pkgrel = 1

pkgname = mypkg-first
	pkgdesc = First package

pkgname = mypkg-second
	pkgdesc = Second package
"""
            si.write_text(si_content)
            self.app.files_cache = {d: []}

            result = self.app._parse_srcinfo(d)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mypkg-first")
            # The desc is from the base as we didn't overwrite it in our naive parsing implementation
            # The code does `data['name'] = v` but keeps older `pkgdesc`

    @patch('pathlib.Path.read_text')
    def test_parse_srcinfo_exception(self, mock_read_text):
        mock_read_text.side_effect = Exception("File read error")
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            (d / "PKGBUILD").touch()
            # Ensure SRCINFO is newer
            old_time = time.time() - 10
            os.utime(d / "PKGBUILD", (old_time, old_time))
            (d / ".SRCINFO").touch()

            self.assertIsNone(self.app._parse_srcinfo(d))

if __name__ == '__main__':
    unittest.main()
