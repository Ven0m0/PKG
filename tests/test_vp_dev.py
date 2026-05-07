import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path
import importlib.util
import os
import sys

# Import vp-dev.py as a module
spec = importlib.util.spec_from_file_location("vp_dev", "vp-dev.py")
vp_dev = importlib.util.module_from_spec(spec)
sys.modules["vp_dev"] = vp_dev
spec.loader.exec_module(vp_dev)

class TestVpDev(unittest.TestCase):
    def setUp(self):
        self.vd = vp_dev.VpDev()

    def test_parse_srcinfo_exception(self):
        """Test that _parse_srcinfo returns None when an exception occurs during parsing."""
        with patch("pathlib.Path.exists", return_value=True):
            # We patch Path.stat as a function, so it doesn't get 'self' passed when called as si.stat()
            # if we use patch("pathlib.Path.stat").
            # Actually, when si.stat() is called, si is the instance.
            with patch("pathlib.Path.stat") as mock_stat:
                srcinfo_stat = MagicMock()
                srcinfo_stat.st_mtime = 200
                pkgbuild_stat = MagicMock()
                pkgbuild_stat.st_mtime = 100

                # Use *args to be safe
                def get_stat(*args, **kwargs):
                    # args[0] should be the Path instance if it's an instance method
                    if args and hasattr(args[0], 'name'):
                         if args[0].name == ".SRCINFO":
                             return srcinfo_stat
                         return pkgbuild_stat
                    return pkgbuild_stat
                mock_stat.side_effect = get_stat

                with patch("pathlib.Path.read_text") as mock_read:
                    mock_read.side_effect = Exception("Parsing error")

                    result = self.vd._parse_srcinfo(Path("fake-pkg"))
                    self.assertIsNone(result)

    def test_parse_srcinfo_success(self):
        """Test the happy path for _parse_srcinfo."""
        with patch("pathlib.Path.exists", return_value=True):
            with patch("pathlib.Path.stat") as mock_stat:
                srcinfo_stat = MagicMock()
                srcinfo_stat.st_mtime = 200
                pkgbuild_stat = MagicMock()
                pkgbuild_stat.st_mtime = 100

                def get_stat(*args, **kwargs):
                    if args and hasattr(args[0], 'name'):
                         if args[0].name == ".SRCINFO":
                             return srcinfo_stat
                    return pkgbuild_stat
                mock_stat.side_effect = get_stat

                with patch("pathlib.Path.read_text") as mock_read:
                    mock_read.return_value = """
pkgbase = test-pkg
	pkgname = test-pkg
	pkgver = 1.0.0
	pkgrel = 1
	pkgdesc = A test package
	url = https://example.com
"""
                    self.vd.files_cache = {Path("test-pkg"): ["file1", "file2"]}

                    result = self.vd._parse_srcinfo(Path("test-pkg"))

                    self.assertIsNotNone(result)
                    self.assertEqual(result["name"], "test-pkg")
                    self.assertEqual(result["version"], "1.0.0-1")
                    self.assertEqual(result["description"], "A test package")
                    self.assertEqual(result["url"], "https://example.com")
                    self.assertEqual(result["files"], ["file1", "file2"])

    def test_parse_srcinfo_missing_files(self):
        """Test _parse_srcinfo when files are missing."""
        with patch("pathlib.Path.exists", return_value=False):
            result = self.vd._parse_srcinfo(Path("missing-pkg"))
            self.assertIsNone(result)

    def test_parse_srcinfo_outdated(self):
        """Test _parse_srcinfo when .SRCINFO is older than PKGBUILD."""
        with patch("pathlib.Path.exists", return_value=True):
            with patch("pathlib.Path.stat") as mock_stat:
                srcinfo_stat = MagicMock()
                srcinfo_stat.st_mtime = 100
                pkgbuild_stat = MagicMock()
                pkgbuild_stat.st_mtime = 200

                def get_stat(*args, **kwargs):
                    if args and hasattr(args[0], 'name'):
                         if args[0].name == ".SRCINFO":
                             return srcinfo_stat
                    return pkgbuild_stat
                mock_stat.side_effect = get_stat

                result = self.vd._parse_srcinfo(Path("outdated-pkg"))
                self.assertIsNone(result)

if __name__ == "__main__":
    unittest.main()
