"""Tests for tools/lib/policy.sh and .github/scripts/bump-lib.sh (bash)."""

import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).parent.parent
POLICY = (ROOT / "tools" / "lib" / "policy.sh").as_posix()
BUMP_LIB = (ROOT / ".github" / "scripts" / "bump-lib.sh").as_posix()
BASH = shutil.which("bash")

# vercmp ships with pacman; a sort -V stand-in keeps these tests portable.
FAKE_VERCMP = """#!/usr/bin/env bash
if [ "$1" = "$2" ]; then echo 0
elif [ "$(printf '%s\\n%s\\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; then echo -1
else echo 1; fi
"""


@unittest.skipUnless(BASH, "bash not available")
class BashCase(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.tmp = Path(tmp.name)

    def bash(self, script, env=None):
        merged = {**os.environ, **(env or {})}
        return subprocess.run(
            [BASH or "bash", "-c", script],
            cwd=self.tmp,
            env=merged,
            capture_output=True,
            text=True,
            check=False,
        ).stdout


class TestPolicy(BashCase):
    def test_srcinfo_exempt(self):
        out = self.bash(
            f'source "{POLICY}"; for p in ghostty uutils/tar chromium; do '
            'srcinfo_exempt "$p" && echo "$p yes" || echo "$p no"; done'
        )
        self.assertEqual(
            out.split("\n")[:3], ["ghostty yes", "uutils/tar yes", "chromium no"]
        )

    def test_update_var(self):
        out = self.bash(
            f'source "{POLICY}"; update_var wine-cachyos; update_var chromium'
        )
        self.assertEqual(out.split(), ["_srctag", "pkgver"])

    def test_filter_pkg_dirs_drops_skipdirs_at_any_depth(self):
        out = self.bash(
            f'source "{POLICY}"; printf "%s\\n" . ghostty uutils/tar patches/x a/docs/b '
            "| filter_pkg_dirs"
        )
        self.assertEqual(out.split(), [".", "ghostty", "uutils/tar"])

    def test_pkgbuild_var_expands_like_makepkg(self):
        (self.tmp / "PKGBUILD").write_text(
            '_srctag=11.0-20261015\npkgver="${_srctag//-/.}"\n'
        )
        out = self.bash(
            f'source "{POLICY}"; pkgbuild_var PKGBUILD pkgver; echo; '
            "pkgbuild_var PKGBUILD missing"
        )
        self.assertEqual(out, "11.0.20261015\n")


class TestBumpDecide(BashCase):
    def setUp(self):
        super().setUp()
        vercmp = self.tmp / "bin" / "vercmp"
        vercmp.parent.mkdir()
        vercmp.write_text(FAKE_VERCMP)
        vercmp.chmod(vercmp.stat().st_mode | stat.S_IEXEC)
        (self.tmp / "old_ver.json").write_text(
            '{"pkg": "1.0", "proton-cachyos-slr": "1.0", "gitpkg": "x"}'
        )

    def decide(self, key, tracked, latest, pkgbuild):
        (self.tmp / key).mkdir(exist_ok=True)
        (self.tmp / key / "PKGBUILD").write_text(pkgbuild)
        env = {
            "PATH": f"{(self.tmp / 'bin').as_posix()}:{os.environ['PATH']}",
            "OLDVER": "old_ver.json",
        }
        out = self.bash(
            f'source "{BUMP_LIB}"; bump_decide "{key}" "{tracked}" "{latest}"', env
        )
        return out.rstrip("\n").split("\t")

    def test_bump(self):
        row = self.decide("pkg", "1.0", "v1.1", "pkgver=1.0\npkgrel=3\n")
        self.assertEqual(row, ["bump", "pkgver 1.0 -> 1.1", "pkgver", "1.1"])

    def test_quoted_pkgver_is_a_plain_bump(self):
        row = self.decide("pkg", "1.0", "1.1", 'pkgver="1.0"\n')
        self.assertEqual(row[0], "bump")

    def test_already_current_is_recorded(self):
        row = self.decide("pkg", "1.0", "1.0", "pkgver=1.0\n")
        self.assertEqual(row[:2], ["recorded", "PKGBUILD already at 1.0"])

    def test_downgrade_goes_to_agent(self):
        row = self.decide("pkg", "1.0", "0.9", "pkgver=1.0\n")
        self.assertEqual(row[:2], ["agent", "0.9 would downgrade pkgver=1.0"])

    def test_srctag_package_writes_srctag(self):
        pkgbuild = '_srctag=1.0\npkgver="${_srctag//-/.}"\n'
        row = self.decide("proton-cachyos-slr", "1.0", "1.1", pkgbuild)
        self.assertEqual(row, ["bump", "_srctag 1.0 -> 1.1", "_srctag", "1.1"])

    def test_pkgver_function_is_recorded_only(self):
        row = self.decide("gitpkg", "x", "y", "pkgver() {\n  echo 1\n}\n")
        self.assertEqual(row[0], "recorded")

    def test_pkgver_function_with_pinned_tag_goes_to_agent(self):
        row = self.decide(
            "gitpkg",
            "x",
            "y",
            "source=(git+https://x#tag=v1)\npkgver() {\n  echo 1\n}\n",
        )
        self.assertEqual(row[0], "agent")

    def test_literal_commit_pin_goes_to_agent(self):
        row = self.decide(
            "pkg", "1.0", "1.1", "source=(git+https://x#commit=abc)\npkgver=1.0\n"
        )
        self.assertEqual(row[:2], ["agent", "source pinned to a literal commit or tag"])

    def test_untracked_key_goes_to_agent(self):
        row = self.decide("other", "1.0", "1.1", "pkgver=1.0\n")
        self.assertEqual(row[:2], ["agent", "not tracked in old_ver.json"])


if __name__ == "__main__":
    unittest.main()
