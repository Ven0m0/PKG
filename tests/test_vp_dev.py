import unittest
import importlib.util
import os
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

# Dynamically import vp-dev.py
spec = importlib.util.spec_from_file_location("vp_dev", os.path.join(os.path.dirname(os.path.dirname(__file__)), "vp-dev.py"))
vp_dev = importlib.util.module_from_spec(spec)
sys.modules["vp_dev"] = vp_dev
spec.loader.exec_module(vp_dev)

class TestVpDev(unittest.TestCase):
    def setUp(self):
        self.app = vp_dev.VpDev()

    def test_parse_srcinfo_missing_files(self):
        # Mocking Path objects
        d = MagicMock(spec=Path)
        si = MagicMock(spec=Path)
        pb = MagicMock(spec=Path)

        # d / ".SRCINFO" -> si
        # d / "PKGBUILD" -> pb
        d.__truediv__.side_effect = lambda x: si if x == ".SRCINFO" else pb

        si.exists.return_value = False
        pb.exists.return_value = True

        self.assertIsNone(self.app._parse_srcinfo(d))

        si.exists.return_value = True
        pb.exists.return_value = False
        self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_stale_srcinfo(self):
        d = MagicMock(spec=Path)
        si = MagicMock(spec=Path)
        pb = MagicMock(spec=Path)

        d.__truediv__.side_effect = lambda x: si if x == ".SRCINFO" else pb

        si.exists.return_value = True
        pb.exists.return_value = True

        si_stat = MagicMock()
        si_stat.st_mtime = 100
        si.stat.return_value = si_stat

        pb_stat = MagicMock()
        pb_stat.st_mtime = 200 # PB is newer than SI
        pb.stat.return_value = pb_stat

        self.assertIsNone(self.app._parse_srcinfo(d))

    def test_parse_srcinfo_success_with_cache(self):
        d = MagicMock(spec=Path)
        si = MagicMock(spec=Path)
        pb = MagicMock(spec=Path)

        d.__truediv__.side_effect = lambda x: si if x == ".SRCINFO" else pb

        si.exists.return_value = True
        pb.exists.return_value = True

        si_stat = MagicMock()
        si_stat.st_mtime = 200
        si.stat.return_value = si_stat

        pb_stat = MagicMock()
        pb_stat.st_mtime = 100 # SI is newer than PB
        pb.stat.return_value = pb_stat

        si.read_text.return_value = """
pkgbase = my-package
	pkgname = my-package
	pkgver = 1.0.0
	pkgrel = 1
	pkgdesc = My awesome package
	url = https://example.com
	arch = x86_64
	license = MIT
"""

        self.app.files_cache = {d: ["file1.txt", "file2.patch", "PKGBUILD"]}

        result = self.app._parse_srcinfo(d)

        self.assertEqual(result, {
            "name": "my-package",
            "version": "1.0.0-1",
            "description": "My awesome package",
            "url": "https://example.com",
            "files": ["file1.txt", "file2.patch"]
        })

    @patch("vp_dev.VpDev._git")
    def test_parse_srcinfo_success_no_cache(self, mock_git):
        d = MagicMock(spec=Path)
        si = MagicMock(spec=Path)
        pb = MagicMock(spec=Path)

        d.__truediv__.side_effect = lambda x: si if x == ".SRCINFO" else pb

        si.exists.return_value = True
        pb.exists.return_value = True

        si_stat = MagicMock()
        si_stat.st_mtime = 200
        si.stat.return_value = si_stat

        pb_stat = MagicMock()
        pb_stat.st_mtime = 100
        pb.stat.return_value = pb_stat

        si.read_text.return_value = """
	pkgname = second-package
	pkgver = 2.5
	pkgrel = 3
	url = https://example.org
"""

        self.app.files_cache = None

        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = "file3.py\nPKGBUILD\nfile4.md\n"
        mock_git.return_value = mock_result

        result = self.app._parse_srcinfo(d)

        mock_git.assert_called_once_with(
            ["ls-files"], capture_output=True, text=True, cwd=d, check=False
        )

        self.assertEqual(result, {
            "name": "second-package",
            "version": "2.5-3",
            "description": "",
            "url": "https://example.org",
            "files": ["file3.py", "file4.md"]
        })

    def test_parse_srcinfo_missing_fields(self):
        d = MagicMock(spec=Path)
        si = MagicMock(spec=Path)
        pb = MagicMock(spec=Path)

        d.__truediv__.side_effect = lambda x: si if x == ".SRCINFO" else pb

        si.exists.return_value = True
        pb.exists.return_value = True

        si_stat = MagicMock()
        si_stat.st_mtime = 200
        si.stat.return_value = si_stat

        pb_stat = MagicMock()
        pb_stat.st_mtime = 100
        pb.stat.return_value = pb_stat

        # Missing pkgrel
        si.read_text.return_value = """
	pkgname = my-package
	pkgver = 1.0.0
"""

        result = self.app._parse_srcinfo(d)
        self.assertIsNone(result)

    def test_parse_srcinfo_exception(self):
        d = MagicMock(spec=Path)
        si = MagicMock(spec=Path)
        pb = MagicMock(spec=Path)

        d.__truediv__.side_effect = lambda x: si if x == ".SRCINFO" else pb

        si.exists.return_value = True
        pb.exists.return_value = True

        si_stat = MagicMock()
        si_stat.st_mtime = 200
        si.stat.return_value = si_stat

        pb_stat = MagicMock()
        pb_stat.st_mtime = 100
        pb.stat.return_value = pb_stat

        si.read_text.side_effect = Exception("Read error")

        result = self.app._parse_srcinfo(d)
        self.assertIsNone(result)

if __name__ == '__main__':
    unittest.main()
