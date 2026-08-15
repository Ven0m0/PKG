---
description: Review the pending PKGBUILD / .SRCINFO changes before committing
agent: pkgbuild-reviewer
subtask: true
---

Review the packaging changes below against
`.opencode/rules/pkgbuild.instructions.md`.

Working tree status:

!`git status --porcelain`

Diff:

!`git diff HEAD -- '*PKGBUILD' '*.SRCINFO' '*.patch' '*.install'`

Report findings only, most severe first. Flag any build output that has been
staged by mistake.
