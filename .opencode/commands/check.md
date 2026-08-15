---
description: Run the repository's lint and validation gates and fix what fails
---

Run this repo's validation and fix whatever fails. Do not add new tooling.

Package lint and metadata:

!`tools/pkg.sh lint 2>&1 | tail -40`

Shell and package lint:

!`make lint 2>&1 | tail -40`

Rules:

- `makepkg`, `updpkgsums`, and `namcap` are Arch-only. If they are missing here,
  run them inside `archlinux:base-devel` rather than reporting the package as
  unverifiable. `bash -n` works anywhere and is not a substitute for the rest.
- Fix the cause, never the check. Do not silence a lint rule to make it pass.
- Regenerate `.SRCINFO` for any PKGBUILD you touch.
- Report anything you could not fix, with the exact failing output.
