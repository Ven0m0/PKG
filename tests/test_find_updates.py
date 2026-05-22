import unittest
import sys
import os
from unittest.mock import MagicMock, patch

# Mock required modules that may not be available (Arch Linux specific)
sys.modules['pyalpm'] = MagicMock()
sys.modules['pycman'] = MagicMock()
sys.modules['pycman.config'] = MagicMock()
sys.modules['requests'] = MagicMock()
sys.modules['colorama'] = MagicMock()

# Add the tools directory to sys.path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'tools'))

from find_updates import PackageBasic


class TestPackageBasicToDict(unittest.TestCase):
    def test_to_dict_empty(self):
        pkg = PackageBasic()
        self.assertEqual(pkg.to_dict(), {})

    def test_to_dict_all_fields(self):
        pkg = PackageBasic(
            id=123,
            name="test-pkg",
            description="A test package",
            package_base_id=456,
            package_base="test-pkg-base",
            maintainer="test-maintainer",
            num_votes=10,
            popularity=5.5,
            first_submitted=100000,
            last_modified=200000,
            out_of_date="12345",
            version="1.0-1",
            url_path="/path/to/pkg",
            url="https://example.com",
        )
        pkg.additional_properties = {"extra_key": "extra_value"}

        result = pkg.to_dict()

        self.assertEqual(result["ID"], 123)
        self.assertEqual(result["Name"], "test-pkg")
        self.assertEqual(result["Description"], "A test package")
        self.assertEqual(result["PackageBaseID"], 456)
        self.assertEqual(result["PackageBase"], "test-pkg-base")
        self.assertEqual(result["Maintainer"], "test-maintainer")
        self.assertEqual(result["NumVotes"], 10)
        self.assertEqual(result["Popularity"], 5.5)
        self.assertEqual(result["FirstSubmitted"], 100000)
        self.assertEqual(result["LastModified"], 200000)
        self.assertEqual(result["OutOfDate"], "12345")
        self.assertEqual(result["Version"], "1.0-1")
        self.assertEqual(result["URLPath"], "/path/to/pkg")
        self.assertEqual(result["URL"], "https://example.com")
        self.assertEqual(result["extra_key"], "extra_value")

    def test_to_dict_partial_fields(self):
        pkg = PackageBasic(id=123, name="test-pkg")
        result = pkg.to_dict()
        self.assertEqual(result["ID"], 123)
        self.assertEqual(result["Name"], "test-pkg")
        self.assertNotIn("Description", result)
        self.assertNotIn("Version", result)


class TestPackageBasicFromDict(unittest.TestCase):
    def test_from_dict_full(self):
        data = {
            "ID": 123,
            "Name": "test-package",
            "Description": "A test package",
            "PackageBaseID": 456,
            "PackageBase": "test-package-base",
            "Maintainer": "maintainer",
            "NumVotes": 42,
            "Popularity": 3.14,
            "FirstSubmitted": 1234567890,
            "LastModified": 1234567890,
            "OutOfDate": None,
            "Version": "1.0.0",
            "URLPath": "/test-package",
            "URL": "https://example.com/test-package",
            "ExtraProperty1": "extra1",
            "ExtraProperty2": 2,
        }

        pkg = PackageBasic.from_dict(data)

        self.assertEqual(pkg.id, 123)
        self.assertEqual(pkg.name, "test-package")
        self.assertEqual(pkg.description, "A test package")
        self.assertEqual(pkg.package_base_id, 456)
        self.assertEqual(pkg.package_base, "test-package-base")
        self.assertEqual(pkg.maintainer, "maintainer")
        self.assertEqual(pkg.num_votes, 42)
        self.assertEqual(pkg.popularity, 3.14)
        self.assertEqual(pkg.first_submitted, 1234567890)
        self.assertEqual(pkg.last_modified, 1234567890)
        self.assertIsNone(pkg.out_of_date)
        self.assertEqual(pkg.version, "1.0.0")
        self.assertEqual(pkg.url_path, "/test-package")
        self.assertEqual(pkg.url, "https://example.com/test-package")
        self.assertEqual(len(pkg.additional_properties), 2)
        self.assertEqual(pkg.additional_properties["ExtraProperty1"], "extra1")
        self.assertEqual(pkg.additional_properties["ExtraProperty2"], 2)
        self.assertNotIn("ID", pkg.additional_properties)

    def test_from_dict_empty(self):
        pkg = PackageBasic.from_dict({})

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

    def test_roundtrip(self):
        original = PackageBasic(
            id=99,
            name="roundtrip-pkg",
            version="2.0-1",
        )
        d = original.to_dict()
        restored = PackageBasic.from_dict(d)
        self.assertEqual(restored.id, 99)
        self.assertEqual(restored.name, "roundtrip-pkg")
        self.assertEqual(restored.version, "2.0-1")


if __name__ == '__main__':
    unittest.main()
