#!/usr/bin/env python3
import argparse
import os
import sys
from pathlib import Path
import logging

format = "%(levelname)s: %(message)s"
logging.basicConfig(stream=sys.stderr, format=format, level=logging.INFO)
logger = logging.getLogger(os.path.basename(__file__))
script_name = os.path.basename(__file__)

workflows_folder = ".github/workflows/"
workflows_path = Path(workflows_folder)

workflow_base = """name: _job_schedule_{name}

permissions:
  actions: write
  contents: write

on:
  workflow_dispatch:
  schedule:
    - cron: '{cron}'

jobs:
"""

job_first = """
  {current}:
    uses: ./.github/workflows/{current}.yml
"""

job_base = """
  {current}:
    needs: {previous}
    uses: ./.github/workflows/{current}.yml
"""

# Categorize packages based on importance/frequency
# This is a guestimation based on the repo content
packages = {
    "weekly": (
        "mesa-git",
        "wine-cachyos",
        "proton-cachyos",
        "proton-cachyos-slr",
        "linux-kernel-catgirl",
        "glibc",
        "llvm",
        "firefox",
        "chromium",
        "obs-studio",
    ),
    "biweekly": (
        "7zip",
        "aria2",
        "ccache-ext",
        "curl",
        "dolphin-emu",
        "ffmpeg",
        "gamescope",
        "handbrake",
        "heroic-games-launcher",
        "mpv",
        "prismlauncher",
        "ryujinx",
        "svt-av1",
        "vscode",
        "wine-tkg-git",
    ),
}

cron = {
    "weekly": "0 0 */7 * *",
    "biweekly": "0 0 */13 * *",
}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=script_name,
        description="Generate schedule workflow for packaging",
    )
    parser.add_argument(
        "--schedule",
        action="store",
        choices={"weekly", "biweekly"},
        choices={"weekly", "biweekly"},
        default="weekly",
    args = parser.parse_args()

    if not os.path.isdir(workflows_folder):
        logger.error(f"'{workflows_folder}' is not a directory.")
        sys.exit(2)

    workflow_file = workflows_path / f"_job_schedule_{args.schedule}.yml"

    if args.schedule not in packages or not packages[args.schedule]:
        logger.info(f"schedule '{args.schedule}' is empty")
        sys.exit(1)

    logger.info(f"generating workflow for '{args.schedule}' builds")
    with workflow_file.open("w") as wf:
        wf.write(workflow_base.format(name=args.schedule, cron=cron[args.schedule]))

        current_packages = packages[args.schedule]
        package = current_packages[0]
        wf.write(job_first.format(current=package))
        previous = package

        for package in current_packages[1:]:
            wf.write(job_base.format(current=package, previous=previous))
            previous = package

    sys.exit(0)
