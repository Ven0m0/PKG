🧪 [testing improvement] Add unit tests for _parse_srcinfo in vp-dev.py

🎯 **What:** The testing gap addressed
The public API `_parse_srcinfo` in `vp-dev.py` was completely untested. This method is critical as it reads `.SRCINFO` files, extracts package metadata, compares file modification times between `.SRCINFO` and `PKGBUILD`, and handles file caching.

📊 **Coverage:** What scenarios are now tested
1. **Missing files**: Returns `None` when either `.SRCINFO` or `PKGBUILD` doesn't exist.
2. **Stale cache**: Returns `None` when `.SRCINFO` is older than `PKGBUILD`.
3. **Cache Hit**: Successfully parses and uses the pre-populated `files_cache`.
4. **Cache Miss**: Successfully triggers `git ls-files` fallback mechanism when `files_cache` is `None` or absent.
5. **Missing Fields**: Correctly returns `None` when `.SRCINFO` is missing required fields like `pkgrel`.
6. **Exception handling**: Catches read/processing exceptions safely and returns `None`.

✨ **Result:** The improvement in test coverage
We now have comprehensive test coverage for `_parse_srcinfo`, ensuring refactors to this method are safe and that regressions can be caught automatically. The tests utilize `importlib.util` to import the root-level script cleanly, avoiding any naming conflicts, and thoroughly mock `pathlib.Path` objects to prevent side-effects on the actual file system.
