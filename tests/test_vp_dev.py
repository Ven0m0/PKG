import unittest
from unittest.mock import patch, MagicMock, mock_open
from pathlib import Path
import sys
import os
import importlib.util
import subprocess

# Dynamically import vp-dev.py using an absolute path relative to this test file
current_dir = Path(os.path.dirname(os.path.abspath(__file__)))
vp_dev_path = current_dir.parent / "vp-dev.py"

spec = importlib.util.spec_from_file_location("vp_dev", vp_dev_path)
vp_dev = importlib.util.module_from_spec(spec)
sys.modules["vp_dev"] = vp_dev
spec.loader.exec_module(vp_dev)

class TestVpDev(unittest.TestCase):
    def setUp(self):
        # We patch sys.stderr/stdout functions if they produce noise,
        # but for this test we mainly mock pathlib.Path and subprocess.run.
        with patch("vp_dev.Path") as MockPath:
            # We need to set a real-ish root for the mock so init doesn't crash
            mock_root = MagicMock(spec=Path)
            MockPath.return_value.parent = mock_root
            mock_root.__truediv__.return_value = MagicMock(spec=Path)

            self.vd = vp_dev.VpDev()
            self.vd.root = Path("/mock/root")
            self.vd.pkg_json = self.vd.root / "packages.json"

    def test_init(self):
        self.assertEqual(str(self.vd.root), "/mock/root")
        self.assertEqual(str(self.vd.pkg_json), "/mock/root/packages.json")
        self.assertIn(".git", self.vd.skip_dirs)

    @patch("vp_dev.subprocess.run")
    def test_parse_pkg_success(self, mock_run):
        # Mock subprocess response for a valid PKGBUILD
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = "testpkg|1.0|2|A test package|https://test.org\n"
        mock_run.return_value = mock_process

        # We need self.files_cache to avoid the git subprocess call in _parse_pkg
        self.vd.files_cache = {Path("/mock/root/testpkg"): ["some_file"]}

        mock_pb = MagicMock(spec=Path)
        mock_pb.exists.return_value = True
        mock_pb.parent = Path("/mock/root/testpkg")

        result = self.vd._parse_pkg(mock_pb)

        self.assertIsNotNone(result)
        self.assertEqual(result["name"], "testpkg")
        self.assertEqual(result["version"], "1.0-2")
        self.assertEqual(result["description"], "A test package")
        self.assertEqual(result["url"], "https://test.org")
        self.assertEqual(result["files"], ["some_file"])

    @patch("vp_dev.subprocess.run")
    def test_parse_pkg_fail(self, mock_run):
        mock_process = MagicMock()
        mock_process.returncode = 1
        mock_run.return_value = mock_process

        mock_pb = MagicMock(spec=Path)
        mock_pb.exists.return_value = True
        mock_pb.parent = Path("/mock/root/testpkg")

        result = self.vd._parse_pkg(mock_pb)
        self.assertIsNone(result)

    def test_parse_srcinfo_success(self):
        mock_d = MagicMock(spec=Path)
        mock_srcinfo = MagicMock(spec=Path)
        mock_d.__truediv__.return_value = mock_srcinfo

        mock_srcinfo.exists.return_value = True
        mock_srcinfo.stat.return_value.st_mtime = 100

        mock_pb = MagicMock(spec=Path)
        mock_pb.stat.return_value.st_mtime = 50

        def truediv_side_effect(name):
            if name == ".SRCINFO":
                return mock_srcinfo
            elif name == "PKGBUILD":
                return mock_pb
            return MagicMock()

        mock_d.__truediv__.side_effect = truediv_side_effect

        srcinfo_content = """
pkgbase = testpkg
	pkgdesc = A test package
	pkgver = 1.0
	pkgrel = 2
	url = https://test.org

pkgname = testpkg
"""
        mock_srcinfo.read_text.return_value = srcinfo_content
        self.vd.files_cache = {mock_d: ["some_file"]}

        result = self.vd._parse_srcinfo(mock_d)

        self.assertIsNotNone(result)
        self.assertEqual(result["name"], "testpkg")
        self.assertEqual(result["version"], "1.0-2")
        self.assertEqual(result["description"], "A test package")
        self.assertEqual(result["url"], "https://test.org")
        self.assertEqual(result["files"], ["some_file"])

    @patch("vp_dev.info")
    @patch("vp_dev.err")
    def test_new_package(self, mock_err, mock_info):
        mock_d = MagicMock(spec=Path)
        mock_d.exists.return_value = False

        mock_pb = MagicMock(spec=Path)

        def truediv_side_effect(name):
            if name == "PKGBUILD":
                return mock_pb
            return MagicMock()

        mock_d.__truediv__.side_effect = truediv_side_effect

        mock_root = MagicMock(spec=Path)
        # When `self.root / "testpkg"` is called
        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()

        mock_root.__truediv__.side_effect = root_truediv_side_effect
        self.vd.root = mock_root

        result = self.vd.new("testpkg")

        self.assertEqual(result, 0)
        mock_d.mkdir.assert_called_with(parents=True)
        mock_pb.write_text.assert_called_once()
        written_text = mock_pb.write_text.call_args[0][0]
        self.assertIn("pkgname=testpkg", written_text)

    @patch("vp_dev.info")
    @patch("vp_dev.err")
    def test_new_package_exists(self, mock_err, mock_info):
        mock_d = MagicMock(spec=Path)
        mock_d.exists.return_value = True

        mock_root = MagicMock(spec=Path)
        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()

        mock_root.__truediv__.side_effect = root_truediv_side_effect
        self.vd.root = mock_root

        result = self.vd.new("testpkg")
        self.assertEqual(result, 1)
        mock_err.assert_called_once()

    @patch("vp_dev.VpDev._get_pkg_dirs")
    @patch("vp_dev.info")
    @patch("vp_dev.ok")
    @patch("vp_dev.shutil.rmtree")
    def test_clean(self, mock_rmtree, mock_ok, mock_info, mock_get_pkg_dirs):
        mock_pkg_dir = MagicMock(spec=Path)
        mock_get_pkg_dirs.return_value = [mock_pkg_dir]

        mock_file = MagicMock(spec=Path)
        mock_file.is_dir.return_value = False

        mock_dir = MagicMock(spec=Path)
        mock_dir.is_dir.return_value = True

        # When pkg_dir.glob is called, return mock files depending on pattern
        def glob_side_effect(pat):
            if pat == "*.log":
                return [mock_file, mock_dir]
            return []

        mock_pkg_dir.glob.side_effect = glob_side_effect

        result = self.vd.clean()

        self.assertEqual(result, 0)
        mock_file.unlink.assert_called_once()
        mock_rmtree.assert_called_once_with(mock_dir)

if __name__ == '__main__':
    unittest.main()
