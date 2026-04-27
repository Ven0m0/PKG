import unittest
import sys
import os
from unittest.mock import MagicMock

# Mock pyalpm, pycman and requests as they are Arch Linux specific
sys.modules['pyalpm'] = MagicMock()
sys.modules['pycman'] = MagicMock()
sys.modules['pycman.config'] = MagicMock()
sys.modules['requests'] = MagicMock()

# Add the tools directory to sys.path
sys.path.append(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'tools'))

from find_updates import PackageBasic

class TestPackageBasic(unittest.TestCase):
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
            url="https://example.com"
        )
        pkg.additional_properties = {"extra_key": "extra_value"}

        expected_dict = {
            "ID": 123,
            "Name": "test-pkg",
            "Description": "A test package",
            "PackageBaseID": 456,
            "PackageBase": "test-pkg-base",
            "Maintainer": "test-maintainer",
            "NumVotes": 10,
            "Popularity": 5.5,
            "FirstSubmitted": 100000,
            "LastModified": 200000,
            "OutOfDate": "12345",
            "Version": "1.0-1",
            "URLPath": "/path/to/pkg",
            "URL": "https://example.com",
            "extra_key": "extra_value"
        }

        self.assertEqual(pkg.to_dict(), expected_dict)

    def test_to_dict_partial_fields(self):
        pkg = PackageBasic(
            id=123,
            name="test-pkg"
        )

        expected_dict = {
            "ID": 123,
            "Name": "test-pkg"
        }

        self.assertEqual(pkg.to_dict(), expected_dict)

if __name__ == '__main__':
    unittest.main()
