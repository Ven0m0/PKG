#!/usr/bin/env python3
import argparse
import os
import sys
from pathlib import Path
import logging

format = "%(levelname)s: %(message)s"
logging.basicConfig(stream=sys.stderr, format=format, level=logging.DEBUG)
logger = logging.getLogger(os.path.basename(__file__))
script_name = os.path.basename(__file__)

workflows_folder = ".github/workflows/"
workflows_path = Path(workflows_folder)

workflow_base = """name: {pkgname}

on:
  workflow_call:
  workflow_dispatch:
    inputs:
      action:
        description: "Repository action"
        required: true
        type: choice
        default: 'build'
        options:
        - 'build'
        - 'remove'
        - 'skip'
  push:
    branches:
     - master
     - main
    paths:
     - {pkgname}/.SRCINFO

jobs:
  repository:
    strategy:
      matrix:
        repository: {repotag}
    uses: ./.github/workflows/_job_pkgrepo.yml
    with:
      pkgdir: {pkgname}
      repository: ${{{{ matrix.repository }}}}
      action: ${{{{ inputs.action != '' && inputs.action || 'build' }}}}
"""

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog=script_name,
        description="Generate workflow for packaging a PKGBUILD",
    )
    parser.add_argument(
        "--repotag",
        action="store",
        choices={"public", "personal", "all"},
        default="public",
        required=False,
    )
    parser.add_argument("path")
    args = parser.parse_args()

    if not os.path.isdir(workflows_folder):
        logger.error(f"'{workflows_folder}' is not a directory.")
        sys.exit(2)

    path = Path(args.path)
    if not path.is_dir():
        logger.error(f"'{path}' is not a directory, exiting.")
        sys.exit(1)

    pkgname = path.name
    workflow_file = workflows_path / f"{pkgname}.yml"

    if args.repotag == "all":
        repotag = "[public, personal]"
    else:
        repotag = f"[{args.repotag}]"

    logger.info("adding workflow for %s to repositories %s", pkgname, repotag)
    with workflow_file.open("w") as wf:
        wf.write(workflow_base.format(pkgname=pkgname, repotag=repotag))

    sys.exit(0)
