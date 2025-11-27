# HandBrake-SVT-AV1-Essential
### Purpose of the project
This project contains the patches needed to replace SVT-AV1 with SVT-AV1-Essential inside HandBrake.\
Based on Ven0m0/HandBrake-SVT-AV1-Essential, this integration additionally includes enhanced features from both HandBrake-SVT-AV1-HDR and HandBrake-SVT-AV1-PSY forks, providing comprehensive support for HDR content encoding and psycho-visual optimizations.

### Features
**From SVT-AV1-Essential base:**
* **SVT-AV1-Essential encoder**: Quality-focused AV1 encoder optimized for better perceived quality
* **Named speed presets**: User-friendly preset names (slower, slow, medium, fast, faster) instead of just numeric values
* **Default AV1 preset**: Optimized default settings using AV1 encoder with VQ tune and Opus audio

**Additional HDR+PSY enhancements:**
* **Extended tune options**: Support for HDR-focused "grain" tune and PSY-focused "subjective ssim" tune, plus "still picture" tune
* **Extended CRF range**: Support for CRF values from 0-70 with 0.25 granularity (vs standard 0-63 with 1.0 granularity)
* **Additional numeric presets**: Extended preset range including -2 and -3 for ultra-slow, highest-quality encoding
* **Neon optimizations**: Fixed compatibility for ARM platforms

### Instructions to patch/build
* Run ```patch.sh``` on linux. The script will patch the previously cloned HandBrake repo. If you want to also clone it you can use ```--clone``` argument.
* Compile for the desired platform using the commands provided on the HandBrake wiki ([BSD](https://handbrake.fr/docs/en/latest/developer/build-bsd.html), [Linux](https://handbrake.fr/docs/en/latest/developer/build-linux.html), [Mac](https://handbrake.fr/docs/en/latest/developer/build-mac.html), [Windows](https://handbrake.fr/docs/en/latest/developer/build-windows.html))

### Credits and Source Forks
This integration is based on and merges features from:
* [Ven0m0/HandBrake-SVT-AV1-Essential](https://github.com/Ven0m0/HandBrake-SVT-AV1-Essential) - Base Essential integration with named presets
* [Uranite/HandBrake-SVT-AV1-HDR](https://github.com/Uranite/HandBrake-SVT-AV1-HDR) - HDR optimizations and grain tune support
* [Nj0be/HandBrake-SVT-AV1-PSY](https://github.com/Nj0be/HandBrake-SVT-AV1-PSY) - PSY optimizations, subjective ssim tune support, and extended CRF

### Downloads and Build Status
Builds are available through the PKGBUILD for Arch Linux users, or can be manually compiled following the instructions above.

### Testing
Help for testing on all platforms would be greatly appreciated.

### Special Thanks
* [Ven0m0](https://github.com/Ven0m0) for HandBrake-SVT-AV1-Essential (base fork)
* [nekotrix](https://github.com/nekotrix) for original HandBrake-SVT-AV1-Essential and SVT-AV1-Essential encoder builds
* [Uranite](https://github.com/Uranite) for HandBrake-SVT-AV1-HDR
* [Nj0be](https://github.com/Nj0be) for HandBrake-SVT-AV1-PSY
* [vincejv](https://github.com/vincejv/docker-handbrake) for Docker container inspiration

