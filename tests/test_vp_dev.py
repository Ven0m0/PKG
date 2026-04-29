import unittest
import importlib.util
from pathlib import Path
from unittest.mock import patch, MagicMock

# Load vp-dev.py module
spec = importlib.util.spec_from_file_location("vp_dev", "vp-dev.py")
vp_dev = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vp_dev)

class TestVpDevParsePkg(unittest.TestCase):
    def setUp(self):
        self.vp = vp_dev.VpDev()

    @patch('pathlib.Path.exists')
    def test_parse_pkg_not_exists(self, mock_exists):
        mock_exists.return_value = False
        self.assertIsNone(self.vp._parse_pkg(Path('nonexistent')))

    @patch('pathlib.Path.exists')
    @patch('subprocess.run')
    def test_parse_pkg_success_git_fallback(self, mock_run, mock_exists):
        mock_exists.return_value = True

        # Mock bash -c ...
        mock_run1 = MagicMock()
        mock_run1.returncode = 0
        mock_run1.stdout = "mypkg|1.0.0|1|My Description|https://example.com"

        # Mock git ls-files fallback via _git method logic
        mock_run2 = MagicMock()
        mock_run2.returncode = 0
        mock_run2.stdout = "file1.patch\nfile2.txt\n"

        mock_run.side_effect = [mock_run1, mock_run2]

        result = self.vp._parse_pkg(Path('/mock/PKGBUILD'))

        self.assertEqual(result, {
            'name': 'mypkg',
            'version': '1.0.0-1',
            'description': 'My Description',
            'url': 'https://example.com',
            'files': ['file1.patch', 'file2.txt']
        })

    @patch('pathlib.Path.exists')
    @patch('subprocess.run')
    def test_parse_pkg_subprocess_failure(self, mock_run, mock_exists):
        mock_exists.return_value = True

        # Mock bash -c failing
        mock_run1 = MagicMock()
        mock_run1.returncode = 1
        mock_run1.stdout = ""

        mock_run.return_value = mock_run1

        self.assertIsNone(self.vp._parse_pkg(Path('/mock/PKGBUILD')))

    @patch('pathlib.Path.exists')
    @patch('subprocess.run')
    def test_parse_pkg_malformed_output(self, mock_run, mock_exists):
        mock_exists.return_value = True

        # Output has less than 4 parts
        mock_run1 = MagicMock()
        mock_run1.returncode = 0
        mock_run1.stdout = "mypkg|1.0.0|1"

        mock_run.return_value = mock_run1

        self.assertIsNone(self.vp._parse_pkg(Path('/mock/PKGBUILD')))

    @patch('pathlib.Path.exists')
    @patch('subprocess.run')
    def test_parse_pkg_with_files_cache(self, mock_run, mock_exists):
        mock_exists.return_value = True

        mock_run1 = MagicMock()
        mock_run1.returncode = 0
        mock_run1.stdout = "mypkg|1.0.0|1|My Description|https://example.com"

        mock_run.return_value = mock_run1

        # Populate files cache
        pb_path = Path('/mock/PKGBUILD')
        self.vp.files_cache = {
            pb_path.parent: ['PKGBUILD', 'file_cache_1.txt', 'file_cache_2.patch']
        }

        result = self.vp._parse_pkg(pb_path)

        # Verify it uses files_cache instead of calling git
        self.assertEqual(mock_run.call_count, 1) # Only bash -c called, no git ls-files
        self.assertEqual(result, {
            'name': 'mypkg',
            'version': '1.0.0-1',
            'description': 'My Description',
            'url': 'https://example.com',
            'files': ['file_cache_1.txt', 'file_cache_2.patch']
        })

    @patch('pathlib.Path.exists')
    @patch('subprocess.run')
    def test_parse_pkg_missing_url(self, mock_run, mock_exists):
        mock_exists.return_value = True

        # Output has exactly 4 parts (no url)
        mock_run1 = MagicMock()
        mock_run1.returncode = 0
        mock_run1.stdout = "mypkg|1.0.0|1|My Description"

        mock_run2 = MagicMock()
        mock_run2.returncode = 0
        mock_run2.stdout = "file1.patch\n"

        mock_run.side_effect = [mock_run1, mock_run2]

        result = self.vp._parse_pkg(Path('/mock/PKGBUILD'))

        self.assertEqual(result, {
            'name': 'mypkg',
            'version': '1.0.0-1',
            'description': 'My Description',
            'url': '',
            'files': ['file1.patch']
        })

if __name__ == '__main__':
    unittest.main()
