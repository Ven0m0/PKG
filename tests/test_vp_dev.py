import pytest
from pathlib import Path
from unittest.mock import MagicMock, patch
import importlib.util
import sys
import os

# Import VpDev from vp-dev.py
spec = importlib.util.spec_from_file_location("vp_dev", "vp-dev.py")
vp_dev = importlib.util.module_from_spec(spec)
sys.modules["vp_dev"] = vp_dev
spec.loader.exec_module(vp_dev)
VpDev = vp_dev.VpDev

@pytest.fixture
def vd():
    return VpDev()

def test_parse_srcinfo_missing_files(vd, tmp_path):
    # Test when .SRCINFO or PKGBUILD is missing
    d = tmp_path / "pkg"
    d.mkdir()

    # Neither exists
    assert vd._parse_srcinfo(d) is None

    # Only .SRCINFO exists
    (d / ".SRCINFO").write_text("pkgname = test")
    assert vd._parse_srcinfo(d) is None

    # Only PKGBUILD exists
    (d / ".SRCINFO").unlink()
    (d / "PKGBUILD").write_text("pkgname=test")
    assert vd._parse_srcinfo(d) is None

def test_parse_srcinfo_outdated(vd, tmp_path):
    # Test when .SRCINFO is older than PKGBUILD
    d = tmp_path / "pkg"
    d.mkdir()
    si = d / ".SRCINFO"
    pb = d / "PKGBUILD"

    si.write_text("pkgname = test")
    pb.write_text("pkgname=test")

    # Set mtime: si is older than pb
    os.utime(si, (100, 100))
    os.utime(pb, (200, 200))

    assert vd._parse_srcinfo(d) is None

def test_parse_srcinfo_success(vd, tmp_path):
    # Test successful parsing
    d = tmp_path / "pkg"
    d.mkdir()
    si = d / ".SRCINFO"
    pb = d / "PKGBUILD"

    si_content = """
pkgbase = testpkg
	pkgdesc = A test package
	pkgver = 1.0.0
	pkgrel = 1
	url = https://example.com
	arch = x86_64
	license = GPL

pkgname = testpkg
"""
    si.write_text(si_content)
    pb.write_text("pkgname=testpkg")

    # Set mtime: si is newer than pb
    os.utime(pb, (100, 100))
    os.utime(si, (200, 200))

    with patch.object(VpDev, '_git') as mock_git:
        mock_git.return_value.returncode = 0
        mock_git.return_value.stdout = "PKGBUILD\n.SRCINFO\nfile1.txt\nfile2.txt"

        result = vd._parse_srcinfo(d)

        assert result is not None
        assert result['name'] == 'testpkg'
        assert result['version'] == '1.0.0-1'
        assert result['description'] == 'A test package'
        assert result['url'] == 'https://example.com'
        assert result['files'] == ['.SRCINFO', 'file1.txt', 'file2.txt']

def test_parse_srcinfo_with_cache(vd, tmp_path):
    # Test parsing using files_cache
    d = tmp_path / "pkg"
    d.mkdir()
    si = d / ".SRCINFO"
    pb = d / "PKGBUILD"

    si.write_text("pkgname = test\npkgver = 1\npkgrel = 1\n")
    pb.write_text("pkgname=test")

    os.utime(pb, (100, 100))
    os.utime(si, (200, 200))

    vd.files_cache = {d: ["PKGBUILD", "cached_file.txt"]}

    result = vd._parse_srcinfo(d)
    assert result['files'] == ["cached_file.txt"]

def test_parse_srcinfo_missing_fields(vd, tmp_path):
    # Test when mandatory fields are missing
    d = tmp_path / "pkg"
    d.mkdir()
    si = d / ".SRCINFO"
    pb = d / "PKGBUILD"

    si.write_text("pkgname = test\npkgver = 1\n") # missing pkgrel
    pb.write_text("pkgname=test")

    os.utime(pb, (100, 100))
    os.utime(si, (200, 200))

    assert vd._parse_srcinfo(d) is None

def test_parse_srcinfo_multiple_packages(vd, tmp_path):
    # Test it stops at first package
    d = tmp_path / "pkg"
    d.mkdir()
    si = d / ".SRCINFO"
    pb = d / "PKGBUILD"

    si_content = """
pkgbase = multi
	pkgver = 1
	pkgrel = 1

pkgname = pkg1
	pkgdesc = First

pkgname = pkg2
	pkgdesc = Second
"""
    si.write_text(si_content)
    pb.write_text("pkgname=(pkg1 pkg2)")

    os.utime(pb, (100, 100))
    os.utime(si, (200, 200))

    vd.files_cache = {d: []}
    result = vd._parse_srcinfo(d)
    assert result['name'] == 'pkg1'
    assert result['description'] == 'First'
