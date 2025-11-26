# VSCodium Patches

This directory contains patches applied during the VSCodium build process.

## Active Patches

### microphone.patch
- **Purpose**: Enables microphone permissions in VSCode webviews
- **Target**: Electron main process and webview configuration
- **Details**: Adds 'microphone' and 'media' to allowed permissions

### translucent.patch
- **Purpose**: Enables window transparency/translucency support
- **Target**: Main window creation and workbench background
- **Details**:
  - Enables transparent window mode in Electron
  - Configures OpenGL rendering for transparency
  - Modifies workbench background to be transparent
  - Adds `window.background` color setting

### vscodium-electron.patch
- **Purpose**: Configures build system to use system Electron
- **Target**: VSCodium build.sh script
- **Details**:
  - Removes Windows/macOS build steps (Linux-only)
  - Configures native modules for system Electron version
  - Skips Remote Extension Host (REH) build

### extension-management.patch
- **Purpose**: Adds extension enable/disable commands
- **Target**: Extension management contribution
- **Details**: Adds `workbench.extensions.enableExtension` and `workbench.extensions.disableExtension` commands

### xterm.patch
- **Purpose**: Xterm terminal enhancements and fixes
- **Target**: Xterm terminal integration
- **Size**: 114K (large patch)

## Patch Application

Patches are automatically applied by VSCodium's build system during the prepare phase. The patches in this directory are copied to VSCodium's `patches/` directory and applied in alphabetical order.

## Notes

- Patches may need adjustment when updating VSCodium versions
- Failed patches should be reviewed and manually reapplied if necessary
- All patches target the vscode submodule within VSCodium
