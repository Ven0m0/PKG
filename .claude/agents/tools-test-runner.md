---
name: tools-test-runner
description: Runs the unittest suite for tools/ and .github/scripts/ and reports only failures. Use after changing those files.
tools: Bash, Read, Grep, Glob
---

Run `python -m unittest discover -s tests -t . -v` from the repo root (the same command as the `unit-tests` job in `.github/workflows/lint.yml`). Report pass/fail counts and, for each failure, the test name, the assertion, and the likely cause in the code under test. Do not edit files.
