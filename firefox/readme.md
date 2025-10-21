- https://build.opensuse.org/package/show/mozilla:Factory/MozillaFirefox
- https://gitlab.com/garuda-linux/firedragon
- [Firefox-opt](https://github.com/Ven0m0/Firefox-opt)
- [firefox-vaapi-opt](https://github.com/lseman/PKGBUILDs/tree/main/firefox-vaapi-opt)

- https://github.com/Betterbird/thunderbird-patches.git
- https://github.com/openSUSE/firefox-maintenance


bash
```
-mllvm=-pgo-temporal-instrumentation
export CFLAGS="-O3 -ffp-contract=fast -march=native"

```


- https://github.com/zen-browser/desktop/blob/e449fc6e2e89fa7bdbea89e0fa8e8a914186f24d/src/build/pgo/profileserver-py.patch#L7
