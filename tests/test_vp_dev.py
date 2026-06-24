import unittest
from unittest.mock import patch, MagicMock, mock_open
import sys
import os
import importlib.util
import io
import subprocess
import tempfile
import time
from pathlib import Path

# Dynamically import vp-dev.py using an absolute path relative to this test file
current_dir = Path(os.path.dirname(os.path.abspath(__file__)))
vp_dev_path = current_dir.parent / "tools" / "vp-dev.py"

spec = importlib.util.spec_from_file_location("vp_dev", vp_dev_path)
vp_dev = importlib.util.module_from_spec(spec)
sys.modules["vp_dev"] = vp_dev
spec.loader.exec_module(vp_dev)


# ─── Output Utilities ────────────────────────────────────────────────────────

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


# ─── _parse_srcinfo ───────────────────────────────────────────────────────────

class TestParseSrcinfo(unittest.TestCase):
    def setUp(self):
        self.app = vp_dev.VpDev()
        self.app.root = Path('/mock/root')
        self.app.files_cache = None

    def test_parse_srcinfo_missing_both_files(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_missing_srcinfo(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            (d / "PKGBUILD").touch()
            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_missing_pkgbuild(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            (d / ".SRCINFO").touch()
            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_older_srcinfo(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"
            si.touch()
            old_time = time.time() - 10
            os.utime(si, (old_time, old_time))
            pb.touch()
            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_successful_with_files_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"
            pb.touch()
            old_time = time.time() - 10
            os.utime(pb, (old_time, old_time))
            si.write_text(
                "pkgbase = mypkg\n"
                "\tpkgdesc = My cool package\n"
                "\tpkgver = 1.0.0\n"
                "\tpkgrel = 2\n"
                "\turl = https://example.com\n"
                "\tarch = x86_64\n"
                "\n"
                "pkgname = mypkg\n"
            )
            self.app.files_cache = {d: ["PKGBUILD", "cached_file.txt", "z_file.txt"]}
            result = self.app._parse_srcinfo(d)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mypkg")
            self.assertEqual(result["version"], "1.0.0-2")
            self.assertEqual(result["description"], "My cool package")
            self.assertEqual(result["url"], "https://example.com")
            self.assertEqual(result["files"], ["cached_file.txt", "z_file.txt"])

    def test_parse_srcinfo_successful_no_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"
            pb.touch()
            old_time = time.time() - 10
            os.utime(pb, (old_time, old_time))
            si.write_text(
                "pkgbase = mypkg\n"
                "\tpkgdesc = My cool package\n"
                "\tpkgver = 1.0.0\n"
                "\tpkgrel = 2\n"
                "\turl = https://example.com\n"
                "\n"
                "pkgname = mypkg\n"
            )
            self.app.files_cache = None
            with patch('subprocess.run') as mock_run:
                mock_result = MagicMock()
                mock_result.returncode = 0
                mock_result.stdout = "PKGBUILD\nsome_patch.patch\nanother_file.txt\n"
                mock_run.return_value = mock_result
                result = self.app._parse_srcinfo(d)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mypkg")
            self.assertEqual(result["version"], "1.0.0-2")
            self.assertEqual(result["files"], ["another_file.txt", "some_patch.patch"])

    def test_parse_srcinfo_incomplete_missing_pkgrel(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"
            pb.touch()
            old_time = time.time() - 10
            os.utime(pb, (old_time, old_time))
            si.write_text(
                "pkgbase = mypkg\n"
                "\tpkgver = 1.0.0\n"
                "\n"
                "pkgname = mypkg\n"
            )
            self.app.files_cache = {d: []}
            self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_multiple_packages_takes_first(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            si = d / ".SRCINFO"
            pb = d / "PKGBUILD"
            pb.touch()
            old_time = time.time() - 10
            os.utime(pb, (old_time, old_time))
            si.write_text(
                "pkgbase = mypkg\n"
                "\tpkgdesc = Base package\n"
                "\tpkgver = 1.0.0\n"
                "\tpkgrel = 1\n"
                "\n"
                "pkgname = mypkg-first\n"
                "\tpkgdesc = First package\n"
                "\n"
                "pkgname = mypkg-second\n"
                "\tpkgdesc = Second package\n"
            )
            self.app.files_cache = {d: []}
            result = self.app._parse_srcinfo(d)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mypkg-first")

    @patch('pathlib.Path.read_text')
    def test_parse_srcinfo_exception(self, mock_read_text):
        mock_read_text.side_effect = Exception("File read error")
        with tempfile.TemporaryDirectory() as tmpdir:
            d = Path(tmpdir)
            pb = d / "PKGBUILD"
            pb.touch()
            old_time = time.time() - 10
            os.utime(pb, (old_time, old_time))
            (d / ".SRCINFO").touch()
            self.assertIsNone(self.app._parse_srcinfo(d))


# ─── _parse_pkg ───────────────────────────────────────────────────────────────

class TestParsePkg(unittest.TestCase):
    def setUp(self):
        self.vp = vp_dev.VpDev()
        self.vp.root = Path('/mock/root')
        self.vp.files_cache = None

    def test_parse_pkg_not_exists(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            # File does not exist
            self.assertIsNone(self.vp._parse_pkg(pb))

    def test_parse_pkg_simple_pkgbuild(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            pb.write_text(
                "pkgname=mypkg\n"
                "pkgver=1.0.0\n"
                "pkgrel=1\n"
                "pkgdesc=My Description\n"
                "url=https://example.com\n"
            )
            self.vp.files_cache = {Path(tmpdir): ["file1.patch", "file2.txt"]}
            result = self.vp._parse_pkg(pb)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mypkg")
            self.assertEqual(result["version"], "1.0.0-1")
            self.assertEqual(result["description"], "My Description")
            self.assertEqual(result["url"], "https://example.com")

    def test_parse_pkg_with_variable_expansion(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            pb.write_text(
                "_pkgname=mypkg\n"
                "pkgname=$_pkgname\n"
                "pkgver=2.0\n"
                "pkgrel=3\n"
                "pkgdesc=Test pkg\n"
                "url=https://example.com\n"
            )
            self.vp.files_cache = {Path(tmpdir): []}
            result = self.vp._parse_pkg(pb)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mypkg")
            self.assertEqual(result["version"], "2.0-3")

    def test_parse_pkg_missing_required_fields(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            pb.write_text("pkgname=mypkg\npkgver=1.0\n")  # Missing pkgrel
            self.vp.files_cache = {Path(tmpdir): []}
            result = self.vp._parse_pkg(pb)
            self.assertIsNone(result)

    def test_parse_pkg_with_files_cache(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            pb.write_text(
                "pkgname=mypkg\n"
                "pkgver=1.0.0\n"
                "pkgrel=1\n"
                "pkgdesc=My Description\n"
                "url=https://example.com\n"
            )
            self.vp.files_cache = {
                Path(tmpdir): ['PKGBUILD', 'file_cache_1.txt', 'file_cache_2.patch']
            }
            result = self.vp._parse_pkg(pb)
            self.assertIsNotNone(result)
            self.assertEqual(result["files"], ["file_cache_1.txt", "file_cache_2.patch"])

    def test_parse_pkg_pkgbase_fallback(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            pb.write_text(
                "pkgbase=mybase\n"
                "pkgver=1.0\n"
                "pkgrel=1\n"
                "pkgdesc=Base package\n"
                "url=https://example.com\n"
            )
            self.vp.files_cache = {Path(tmpdir): []}
            result = self.vp._parse_pkg(pb)
            self.assertIsNotNone(result)
            self.assertEqual(result["name"], "mybase")

    def test_parse_pkg_skips_comments(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            pb = Path(tmpdir) / "PKGBUILD"
            pb.write_text(
                "# Maintainer: someone\n"
                "pkgname=mypkg\n"
                "pkgver=1.0.0\n"
                "pkgrel=1\n"
                "# pkgdesc=This is a comment\n"
                "pkgdesc=Real description\n"
                "url=https://example.com\n"
            )
            self.vp.files_cache = {Path(tmpdir): []}
            result = self.vp._parse_pkg(pb)
            self.assertIsNotNone(result)
            self.assertEqual(result["description"], "Real description")


# ─── VpDev init and new ───────────────────────────────────────────────────────

class TestVpDev(unittest.TestCase):
    def setUp(self):
        with patch("vp_dev.Path") as MockPath:
            mock_root = MagicMock(spec=Path)
            MockPath.return_value.parent = mock_root
            mock_root.__truediv__.return_value = MagicMock(spec=Path)
            self.vd = vp_dev.VpDev()
            self.vd.root = Path("/mock/root")
            self.vd.pkg_json = self.vd.root / "packages.json"

    def test_init(self):
        self.assertEqual(str(self.vd.root), "/mock/root")
        self.assertIn(".git", self.vd.skip_dirs)

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
        mock_file.name = "test.log"

        mock_dir = MagicMock(spec=Path)
        mock_dir.is_dir.return_value = True
        mock_dir.name = "pkg"

        def iterdir_side_effect():
            return [mock_file, mock_dir]

        mock_pkg_dir.iterdir.side_effect = iterdir_side_effect

        result = self.vd.clean()
        self.assertEqual(result, 0)
        mock_file.unlink.assert_called_once()
        mock_rmtree.assert_called_once_with(mock_dir)



    @patch("vp_dev.err")
    def test_updpkgsums_pkg_not_found(self, mock_err):
        mock_d = MagicMock(spec=Path)
        mock_d.exists.return_value = False
        mock_root = MagicMock(spec=Path)

        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()

        mock_root.__truediv__.side_effect = root_truediv_side_effect
        self.vd.root = mock_root

        result = self.vd.updpkgsums("testpkg")

        self.assertEqual(result, 1)
        mock_err.assert_called_once_with("Package 'testpkg' not found!")

    @patch("vp_dev.err")
    def test_updpkgsums_no_pkgbuild(self, mock_err):
        mock_d = MagicMock(spec=Path)
        mock_pb = MagicMock(spec=Path)

        def d_exists():
            return True
        mock_d.exists.side_effect = d_exists

        def pb_exists():
            return False
        mock_pb.exists.side_effect = pb_exists

        def d_truediv_side_effect(name):
            if name == "PKGBUILD":
                return mock_pb
            return MagicMock()
        mock_d.__truediv__.side_effect = d_truediv_side_effect

        mock_root = MagicMock(spec=Path)
        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()
        mock_root.__truediv__.side_effect = root_truediv_side_effect

        self.vd.root = mock_root

        result = self.vd.updpkgsums("testpkg")

        self.assertEqual(result, 1)
        mock_err.assert_called_once_with("No PKGBUILD found in testpkg")

    @patch("vp_dev.ok")
    @patch("vp_dev.info")
    @patch("vp_dev.subprocess.run")
    def test_updpkgsums_success(self, mock_run, mock_info, mock_ok):
        mock_d = MagicMock(spec=Path)
        mock_pb = MagicMock(spec=Path)
        mock_srcinfo = MagicMock(spec=Path)

        mock_d.exists.return_value = True
        mock_pb.exists.return_value = True

        def d_truediv_side_effect(name):
            if name == "PKGBUILD":
                return mock_pb
            elif name == ".SRCINFO":
                return mock_srcinfo
            return MagicMock()
        mock_d.__truediv__.side_effect = d_truediv_side_effect

        mock_root = MagicMock(spec=Path)
        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()
        mock_root.__truediv__.side_effect = root_truediv_side_effect
        self.vd.root = mock_root

        mock_r1 = MagicMock()
        mock_r1.returncode = 0
        mock_r2 = MagicMock()
        mock_r2.returncode = 0
        mock_r2.stdout = "srcinfo content"
        mock_run.side_effect = [mock_r1, mock_r2]

        result = self.vd.updpkgsums("testpkg")

        self.assertEqual(result, 0)
        self.assertEqual(mock_run.call_count, 2)

        # Verify subprocess.run calls
        mock_run.assert_any_call(
            ["updpkgsums"], cwd=mock_d, capture_output=True, text=True, check=False
        )
        mock_run.assert_any_call(
            ["makepkg", "--printsrcinfo"], cwd=mock_d, capture_output=True, text=True, check=False
        )

        mock_srcinfo.write_text.assert_called_once_with("srcinfo content")
        self.assertEqual(mock_ok.call_count, 2)
        mock_ok.assert_any_call("Updated checksums for testpkg")
        mock_ok.assert_any_call("Generated .SRCINFO")

    @patch("vp_dev.warn")
    @patch("vp_dev.ok")
    @patch("vp_dev.info")
    @patch("vp_dev.subprocess.run")
    def test_updpkgsums_makepkg_fails(self, mock_run, mock_info, mock_ok, mock_warn):
        mock_d = MagicMock(spec=Path)
        mock_pb = MagicMock(spec=Path)

        mock_d.exists.return_value = True
        mock_pb.exists.return_value = True

        def d_truediv_side_effect(name):
            if name == "PKGBUILD":
                return mock_pb
            return MagicMock()
        mock_d.__truediv__.side_effect = d_truediv_side_effect

        mock_root = MagicMock(spec=Path)
        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()
        mock_root.__truediv__.side_effect = root_truediv_side_effect
        self.vd.root = mock_root

        mock_r1 = MagicMock()
        mock_r1.returncode = 0
        mock_r2 = MagicMock()
        mock_r2.returncode = 1
        mock_run.side_effect = [mock_r1, mock_r2]

        result = self.vd.updpkgsums("testpkg")

        self.assertEqual(result, 0)
        self.assertEqual(mock_run.call_count, 2)
        mock_warn.assert_called_once_with("Failed to generate .SRCINFO")

    @patch("vp_dev.err")
    @patch("vp_dev.info")
    @patch("vp_dev.subprocess.run")
    def test_updpkgsums_updpkgsums_fails(self, mock_run, mock_info, mock_err):
        mock_d = MagicMock(spec=Path)
        mock_pb = MagicMock(spec=Path)

        mock_d.exists.return_value = True
        mock_pb.exists.return_value = True

        def d_truediv_side_effect(name):
            if name == "PKGBUILD":
                return mock_pb
            return MagicMock()
        mock_d.__truediv__.side_effect = d_truediv_side_effect

        mock_root = MagicMock(spec=Path)
        def root_truediv_side_effect(name):
            if name == "testpkg":
                return mock_d
            return MagicMock()
        mock_root.__truediv__.side_effect = root_truediv_side_effect
        self.vd.root = mock_root

        mock_r1 = MagicMock()
        mock_r1.returncode = 1
        mock_r1.stderr = "error output"
        mock_run.return_value = mock_r1

        result = self.vd.updpkgsums("testpkg")

        self.assertEqual(result, 1)
        mock_run.assert_called_once()
        mock_err.assert_called_once_with("Failed to update checksums: error output")


if __name__ == '__main__':
    unittest.main()
