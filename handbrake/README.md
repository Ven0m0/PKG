# HandBrake-SVT-AV1-HDR+PSY
### Purpose of the project
This project contains the patches needed to integrate SVT-AV1-PSY with HandBrake, combining features from both HandBrake-SVT-AV1-HDR and HandBrake-SVT-AV1-PSY forks.\
This merged integration provides enhanced support for HDR content and psycho-visual optimizations.
### Features
This merged integration includes:
* **SVT-AV1-PSY encoder**: Psycho-visual optimizations for better perceived quality
* **Extended tune options**: Support for both HDR-focused "grain" tune and PSY-focused "subjective ssim" tune, plus "still picture" tune
* **Extended CRF range**: Support for CRF values from 0-70 with 0.25 granularity (vs standard 0-63 with 1.0 granularity)
* **Additional presets**: Extended preset range including -2 and -3 for ultra-slow, highest-quality encoding
* **Neon optimizations**: Fixed compatibility for ARM platforms

### Instructions to patch/build
* Run ```patch.sh``` on linux. The script will patch the previously cloned HandBrake repo. If you want to also clone it you can use ```--clone``` argument.
* Compile for the desired platform using the commands provided on the HandBrake wiki ([BSD](https://handbrake.fr/docs/en/latest/developer/build-bsd.html), [Linux](https://handbrake.fr/docs/en/latest/developer/build-linux.html), [Mac](https://handbrake.fr/docs/en/latest/developer/build-mac.html), [Windows](https://handbrake.fr/docs/en/latest/developer/build-windows.html))

### Credits and Source Forks
This integration merges features from:
* [Uranite/HandBrake-SVT-AV1-HDR](https://github.com/Uranite/HandBrake-SVT-AV1-HDR) - HDR optimizations and grain tune support
* [Nj0be/HandBrake-SVT-AV1-PSY](https://github.com/Nj0be/HandBrake-SVT-AV1-PSY) - PSY optimizations and subjective ssim tune support

### Downloads and Build Status
Builds are available through the PKGBUILD for Arch Linux users, or can be manually compiled following the instructions above.

### Testing
Help for testing on all platforms would be greatly appreciated.

### Special Thanks
* [Uranite](https://github.com/Uranite) for HandBrake-SVT-AV1-HDR
* [Nj0be](https://github.com/Nj0be) for HandBrake-SVT-AV1-PSY
* [nekotrix](https://github.com/nekotrix) for HandBrake-SVT-AV1-Essential (base project)
* [vincejv](https://github.com/vincejv/docker-handbrake) for Docker container inspiration

