#!/usr/bin/env python3
"""Diff nvchecker results against the tracked versions.

Prints GITHUB_OUTPUT lines for _update-pkgbuilds.yml: has_drift, drift (a
markdown list), and drift_tsv (key, tracked, latest) for bump-pkgbuilds.sh.
PACKAGES (space-separated keys) narrows the result; FORCE=true sets has_drift.
"""

import json
import os
import sys
from pathlib import Path

OLD_VER = Path(".github/nvchecker/old_ver.json")
NEW_VER = Path(".github/nvchecker/new_ver.json")


def load(path):
    """Read either nvchecker format as a flat {name: version} map.

    nvchecker writes the v2 shape ({"version": 2, "data": {name:
    {"version": ...}}}) but still reads the legacy flat map, which is what
    old_ver.json in this repo is.
    """
    data = json.loads(Path(path).read_text())
    if isinstance(data, dict) and data.get("version") == 2:
        return {k: v["version"] for k, v in data.get("data", {}).items()}
    return data


def find_drift(old, new, wanted=frozenset()):
    """Sorted (name, tracked, latest) rows where latest differs from tracked."""
    return sorted(
        (name, old.get(name, "<untracked>"), version)
        for name, version in new.items()
        if old.get(name) != version and (not wanted or name in wanted)
    )


def render(drift, forced=False):
    """Format drift rows as GITHUB_OUTPUT lines."""
    lines = [f"has_drift={'true' if drift or forced else 'false'}", "drift<<NVDRIFT"]
    lines += [f"- {name}: {before} -> {after}" for name, before, after in drift]
    lines += ["NVDRIFT", "drift_tsv<<NVTSV"]
    lines += ["\t".join(row) for row in drift]
    lines.append("NVTSV")
    return "\n".join(lines) + "\n"


def main():
    # nvchecker always checks every entry; honour the dispatch filter here.
    wanted = frozenset(os.environ.get("PACKAGES", "").split())
    drift = find_drift(load(OLD_VER), load(NEW_VER), wanted)
    sys.stdout.write(render(drift, os.environ.get("FORCE") == "true"))


if __name__ == "__main__":
    main()
