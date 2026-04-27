import sys
import os
import unittest
from unittest.mock import MagicMock

# Mock required modules that may not be available
sys.modules['pyalpm'] = MagicMock()
sys.modules['pycman'] = MagicMock()
sys.modules['pycman.config'] = MagicMock()
sys.modules['requests'] = MagicMock()

import importlib.util
spec = importlib.util.spec_from_file_location("find_updates", os.path.abspath(os.path.join(os.path.dirname(__file__), "../tools/find_updates.py")))
find_updates = importlib.util.module_from_spec(spec)
sys.modules["find_updates"] = find_updates
spec.loader.exec_module(find_updates)

class TestPackageBasic(unittest.TestCase):
    def test_from_dict_full(self):
        data = {
            "ID": 123,
            "Name": "test-package",
            "Description": "A test package",
            "PackageBaseID": 456,
            "PackageBase": "test-package-base",
            "Maintainer": "jules",
            "NumVotes": 42,
            "Popularity": 3.14,
            "FirstSubmitted": 1234567890,
            "LastModified": 1234567890,
            "OutOfDate": None,
            "Version": "1.0.0",
            "URLPath": "/test-package",
            "URL": "https://example.com/test-package",
            "ExtraProperty1": "extra1",
            "ExtraProperty2": 2
        }

        pkg = find_updates.PackageBasic.from_dict(data)

        self.assertEqual(pkg.id, 123)
        self.assertEqual(pkg.name, "test-package")
        self.assertEqual(pkg.description, "A test package")
        self.assertEqual(pkg.package_base_id, 456)
        self.assertEqual(pkg.package_base, "test-package-base")
        self.assertEqual(pkg.maintainer, "jules")
        self.assertEqual(pkg.num_votes, 42)
        self.assertEqual(pkg.popularity, 3.14)
        self.assertEqual(pkg.first_submitted, 1234567890)
        self.assertEqual(pkg.last_modified, 1234567890)
        self.assertIsNone(pkg.out_of_date)
        self.assertEqual(pkg.version, "1.0.0")
        self.assertEqual(pkg.url_path, "/test-package")
        self.assertEqual(pkg.url, "https://example.com/test-package")

        # Test additional properties are preserved
        self.assertEqual(pkg.additional_properties["ExtraProperty1"], "extra1")
        self.assertEqual(pkg.additional_properties["ExtraProperty2"], 2)

    def test_from_dict_empty(self):
        pkg = find_updates.PackageBasic.from_dict({})

        self.assertIsNone(pkg.id)
        self.assertIsNone(pkg.name)
        self.assertIsNone(pkg.description)
        self.assertIsNone(pkg.package_base_id)
        self.assertIsNone(pkg.package_base)
        self.assertIsNone(pkg.maintainer)
        self.assertIsNone(pkg.num_votes)
        self.assertIsNone(pkg.popularity)
        self.assertIsNone(pkg.first_submitted)
        self.assertIsNone(pkg.last_modified)
        self.assertIsNone(pkg.out_of_date)
        self.assertIsNone(pkg.version)
        self.assertIsNone(pkg.url_path)
        self.assertIsNone(pkg.url)
        self.assertEqual(pkg.additional_properties, {})

if __name__ == '__main__':
    unittest.main()
