#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Default directories
readonly dxvk_lib32="${dxvk_lib32:-x32}"
readonly dxvk_lib64="${dxvk_lib64:-x64}"

# Figure out where we are
readonly basedir="$(dirname "$(readlink -f "$0")")"

# Figure out which action to perform
action="$1"

case "$action" in
install | uninstall) ;;
*)
  echo "Unrecognized action: $action"
  echo "Usage: $0 [install|uninstall] [--without-dxgi] [--symlink]"
  exit 1
  ;;
esac

# Process arguments
shift

with_dxgi=true
file_cmd="cp -v --reflink=auto"

while (($# > 0)); do
  case "$1" in
  "--without-dxgi")
    with_dxgi=false
    ;;
  "--symlink")
    file_cmd="ln -s -v"
    ;;
  esac
  shift
done

readonly wineserver="wineserver"
wine_path=$(dirname "$(command -v $wineserver)")
echo "Using Wine installation in $(dirname "$wine_path")"
readonly wine="${wine_path}/wine"
readonly wine64="${wine_path}/wine64"

if [ -z "$WINEPREFIX" ]; then
  WINEPREFIX="$HOME/.wine"
fi

# Wait for any existing wine processes
"$wineserver" -w

# Check wine prefix
if [ -n "$WINEPREFIX" ] && ! [ -f "$WINEPREFIX/system.reg" ]; then
  echo "$WINEPREFIX: Not a valid wine prefix." >&2
  exit 1
fi

# Find wine executable
export WINEDEBUG=-all
export WINEDLLOVERRIDES="mscoree,mshtml="

# Detect architecture
if [ -z "$WINEARCH" ]; then
  if [ -f "$WINEPREFIX"/system.reg ]; then
    arch="$(grep "^#arch=win" "$WINEPREFIX"/system.reg)"
    arch="${arch##*=}"
  else
    arch=win64
  fi
else
  arch="$WINEARCH"
fi

wine_ver="$("$wineserver" --version 2>&1 >/dev/null | grep Wine)"
if [ -z "$wine_ver" ]; then
  echo "$wineserver: Not a wine executable." >&2
  exit 1
fi

# Get system paths
readonly system32_path=$("${wine64:-$wine}" winepath.exe -u 'C:\windows\system32' 2>/dev/null | tr -d '\r')
readonly syswow64_path=$("${wine64:-$wine}" winepath.exe -u 'C:\windows\syswow64' 2>/dev/null | tr -d '\r')

if [ -z "$syswow64_path" ] && [ -z "$system32_path" ]; then
  echo 'Failed to resolve C:\windows\system32.' >&2
  exit 1
fi

# Create native dll override
overrideDll() {
  "${wine64:-$wine}" reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v "$1" /d native /f >/dev/null 2>&1
}

# Remove dll override
restoreDll() {
  "${wine64:-$wine}" reg delete 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v "$1" /f >/dev/null 2>&1 || true
}

# Install file
installFile() {
  local dstfile="${1}/${3}.dll"
  local srcfile="${basedir}/${2}/${3}.dll"

  if ! [ -f "${srcfile}" ]; then
    echo "${srcfile}: File not found. Skipping." >&2
    return 1
  fi

  if [ -n "$1" ]; then
    if [ -f "${dstfile}" ] || [ -h "${dstfile}" ]; then
      if ! [ -f "${dstfile}.old" ]; then
        mv -v "${dstfile}" "${dstfile}.old"
      else
        rm -v "${dstfile}"
      fi
    fi
    $file_cmd "${srcfile}" "${dstfile}"
  fi
  return 0
}

# Uninstall file
uninstallFile() {
  local dstfile="${1}/${3}.dll"
  local srcfile="${basedir}/${2}/${3}.dll"

  if ! [ -f "${srcfile}" ]; then
    echo "${srcfile}: File not found. Skipping." >&2
    return 1
  fi

  if ! [ -f "${dstfile}" ] && ! [ -h "${dstfile}" ]; then
    echo "${dstfile}: File not found. Skipping." >&2
    return 1
  fi

  if [ -f "${dstfile}.old" ]; then
    rm -v "${dstfile}"
    mv -v "${dstfile}.old" "${dstfile}"
    return 0
  fi
  return 1
}

install() {
  local lib dll
  if [ "$arch" == "win32" ]; then
    lib="$dxvk_lib32"
    dll="${1}"
  else
    lib="$dxvk_lib64"
    dll="${1}"
  fi

  if installFile "$system32_path" "$lib" "$dll"; then
    overrideDll "$dll"
  fi

  if [ -d "$syswow64_path" ]; then
    if installFile "$syswow64_path" "$dxvk_lib32" "$1"; then
      overrideDll "$1"
    fi
  fi
}

uninstall() {
  local lib dll
  if [ "$arch" == "win32" ]; then
    lib="$dxvk_lib32"
    dll="${1}"
  else
    lib="$dxvk_lib64"
    dll="${1}"
  fi

  if uninstallFile "$system32_path" "$lib" "$dll"; then
    restoreDll "$dll"
  fi

  if [ -d "$syswow64_path" ]; then
    if uninstallFile "$syswow64_path" "$dxvk_lib32" "$1"; then
      restoreDll "$1"
    fi
  fi
}

# Install/uninstall DLLs
if $with_dxgi || [ "$action" == "uninstall" ]; then
  $action dxgi
fi

$action d3d8
$action d3d9
$action d3d10core
$action d3d11
