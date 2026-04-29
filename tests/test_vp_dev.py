import unittest
from unittest.mock import MagicMock, patch
from pathlib import Path
import importlib.util

spec = importlib.util.spec_from_file_location('vp_dev', 'vp-dev.py')
vp_dev = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vp_dev)

class TestVpDevParseSrcinfo(unittest.TestCase):
    def setUp(self):
        self.vd = vp_dev.VpDev()

    def _setup_mock_dir(self, si_exists=True, pb_exists=True, si_mtime=200, pb_mtime=100, si_content=None):
        d = MagicMock(spec=Path)

        si = MagicMock(spec=Path)
        si.exists.return_value = si_exists
        si_stat = MagicMock()
        si_stat.st_mtime = si_mtime
        si.stat.return_value = si_stat
        if si_content is not None:
            si.read_text.return_value = si_content
        else:
            si.read_text.side_effect = Exception("Read error")

        pb = MagicMock(spec=Path)
        pb.exists.return_value = pb_exists
        pb_stat = MagicMock()
        pb_stat.st_mtime = pb_mtime
        pb.stat.return_value = pb_stat

        def d_truediv(other):
            if other == ".SRCINFO":
                return si
            elif other == "PKGBUILD":
                return pb
            return MagicMock(spec=Path)

        d.__truediv__.side_effect = d_truediv
        return d, si, pb

    def test_parse_srcinfo_success_with_files_cache(self):
        si_content = """pkgbase = test-package
	pkgdesc = Test package description
	pkgver = 1.0.0
	pkgrel = 1
	url = https://example.com/test-package
	arch = x86_64

pkgname = test-package
"""
        d, _, _ = self._setup_mock_dir(si_content=si_content)
        self.vd.files_cache = {d: ["PKGBUILD", "file1.txt", "file2.patch"]}

        result = self.vd._parse_srcinfo(d)

        self.assertIsNotNone(result)
        self.assertEqual(result["name"], "test-package")
        self.assertEqual(result["version"], "1.0.0-1")
        self.assertEqual(result["description"], "Test package description")
        self.assertEqual(result["url"], "https://example.com/test-package")
        self.assertEqual(result["files"], ["file1.txt", "file2.patch"])

    @patch('subprocess.run')
    def test_parse_srcinfo_success_with_git(self, mock_subprocess_run):
        si_content = """pkgbase = test-package
	pkgdesc = Test package description
	pkgver = 1.0.0
	pkgrel = 1
	url = https://example.com/test-package
	arch = x86_64

pkgname = test-package
"""
        d, _, _ = self._setup_mock_dir(si_content=si_content)
        self.vd.files_cache = None

        mock_r = MagicMock()
        mock_r.returncode = 0
        mock_r.stdout = "PKGBUILD\nfile1.txt\nfile2.patch\n"
        mock_subprocess_run.return_value = mock_r

        result = self.vd._parse_srcinfo(d)

        self.assertIsNotNone(result)
        self.assertEqual(result["name"], "test-package")
        self.assertEqual(result["version"], "1.0.0-1")
        self.assertEqual(result["description"], "Test package description")
        self.assertEqual(result["url"], "https://example.com/test-package")
        self.assertEqual(result["files"], ["file1.txt", "file2.patch"])
        mock_subprocess_run.assert_called_once_with(["/usr/bin/git", "ls-files"], capture_output=True, text=True, cwd=d, check=False)

    def test_parse_srcinfo_missing_si(self):
        d, _, _ = self._setup_mock_dir(si_exists=False)
        self.assertIsNone(self.vd._parse_srcinfo(d))

    def test_parse_srcinfo_missing_pb(self):
        d, _, _ = self._setup_mock_dir(pb_exists=False)
        self.assertIsNone(self.vd._parse_srcinfo(d))

    def test_parse_srcinfo_stale_si(self):
        d, _, _ = self._setup_mock_dir(si_mtime=100, pb_mtime=200)
        self.assertIsNone(self.vd._parse_srcinfo(d))

    def test_parse_srcinfo_exception_handling(self):
        d, _, _ = self._setup_mock_dir(si_content=None) # read_text raises Exception
        self.assertIsNone(self.vd._parse_srcinfo(d))

    def test_parse_srcinfo_incomplete_data(self):
        si_content = """pkgbase = test-package
	pkgdesc = Test package description
	pkgver = 1.0.0
""" # Missing pkgrel and pkgname
        d, _, _ = self._setup_mock_dir(si_content=si_content)
        self.assertIsNone(self.vd._parse_srcinfo(d))

if __name__ == '__main__':
    unittest.main()
