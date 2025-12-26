#!/usr/bin/env bash
# shellcheck enable=all shell=bash source-path=SCRIPTDIR
set -euo pipefail; shopt -s nullglob globstar
IFS=$'\n\t' LC_ALL=C

has(){ command -v -- "$1" &>/dev/null; }
msg(){ printf '%s\n' "$@"; }
log(){ printf '%s\n' "$@" >&2; }
die(){ printf '%s\n' "$1" >&2; exit "${2:-1}"; }
R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
warn(){ log "${Y}WARN${D} $*"; }
ok(){ log "${G}OK${D} $*"; }
err(){ log "${R}ERR${D} $*"; }
has jq || die "Need jq"
dl(){
  local u=$1 o=$2
  mkdir -p "${o%/*}"
  if has curl; then
    curl -fsSL --retry 3 --http2 --tlsv1.2 "$u" -o "$o"
  elif has wget; then
    wget -qO "$o" "$u"
  else
    die "Need curl or wget"
  fi
}
user_home(){
  local u=${SUDO_USER:-${USER:-}}
  [[ -n $u ]] || die "No USER/SUDO_USER detected"
  local h
  h=$(getent passwd "$u" 2>/dev/null | cut -d: -f6 || true)
  [[ -n $h && -d $h ]] || h=${HOME:-}
  [[ -n $h && -d $h ]] || die "Cannot resolve home for $u"
  printf '%s\n' "$h"
}
keys_json(){ local -n a=$1; printf '%s\n' "${a[@]}" | jq -R .  | jq -s .; }
KEYS_PROD=(
  nameShort nameLong applicationName dataFolderName serverDataFolderName
  darwinBundleIdentifier linuxIconName licenseUrl
  extensionAllowedProposedApi extensionEnabledApiProposals extensionKind extensionPointExtensionKind
  extensionSyncedKeys extensionVirtualWorkspacesSupport extensionsGallery
  extensionTips extensionImportantTips exeBasedExtensionTips
  configBasedExtensionTips keymapExtensionTips languageExtensionTips remoteExtensionTips
  webExtensionTips virtualWorkspaceExtensionTips
  trustedExtensionAuthAccess trustedExtensionUrlPublicKeys auth
  configurationSync "configurationSync.store" editSessions "editSessions.store"
  settingsSync aiConfig commandPaletteSuggestedCommandIds
  extensionRecommendations extensionKeywords extensionAllowedBadgeProviders
  extensionAllowedBadgeProvidersRegex linkProtectionTrustedDomains
  msftInternalDomains documentationUrl introductoryVideosUrl tipsAndTricksUrl newsletterSignupUrl releaseNotesUrl
  keyboardShortcutsUrlMac keyboardShortcutsUrlLinux keyboardShortcutsUrlWin
  quality settingsSearchUrl tasConfig tunnelApplicationName
  tunnelApplicationConfig serverApplicationName serverGreeting urlProtocol
  webUrl webEndpointUrl webEndpointUrlTemplate
  webviewContentExternalBaseUrlTemplate builtInExtensions
  extensionAllowedExtensionKinds crash aiRelatedInformationUrl defaultChatAgent
)
extract_vscode_product_json(){
  local ver=$1 out=$2 tmp
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  dl "https://update.code.visualstudio.com/${ver}/linux-x64/stable" "$tmp/code.tgz"
  tar xf "$tmp/code.tgz" -C "$tmp" --strip-components=3 \
    VSCode-linux-x64/resources/app/product.json 2>/dev/null || die "Extract failed"
  mv "$tmp/product.json" "$out"
}
update_patch_from_version(){
  local ver=$1 out_patch=$2; shift 2
  local -n kref=$1
  [[ -n $ver ]] || die "Version required"
  local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  dl "https://update.code.visualstudio.com/${ver}/linux-x64/stable" "$tmp/code.tgz"
  tar xf "$tmp/code. tgz" -C "$tmp" --strip-components=3 \
    VSCode-linux-x64/resources/app/product.json 2>/dev/null || die "Extract failed"
  jq -r --argjson k "$(keys_json kref)" '
    reduce $k[] as $x ({}; . + {($x): (getpath($x|split(". "))?)}) |
    . + {enableTelemetry:false}
  ' "$tmp/product.json" >"$out_patch"
  ok "Updated patch -> $out_patch"
  [[ -f ./PKGBUILD ]] && has updpkgsums && updpkgsums ./PKGBUILD &>/dev/null || :
}
json_apply(){
  local prod=$1 patch=$2 cache=$3 tmp
  [[ -f $prod ]] || { warn "Missing product: $prod"; return 0; }
  [[ -f $patch ]] || die "Missing patch: $patch"
  [[ -f $cache ]] || printf '{}' >"$cache"
  tmp=$(mktemp)
  jq -s '
    .[0] as $b | .[1] as $p |
    ($b|to_entries|map(select(.key as $k | $p|has($k)))|from_entries) as $c |
    {p:($b+$p), c:$c}
  ' "$prod" "$patch" >"$tmp" || die "jq apply failed"
  jq -r . p "$tmp" >"$prod"
  jq -r .c "$tmp" >"$cache"
  rm -f "$tmp"
  ok "Applied -> $prod"
}
json_restore(){
  local prod=$1 patch=$2 cache=$3 tmp
  [[ -f $prod ]] || die "Missing product: $prod"
  [[ -f $patch ]] || die "Missing patch: $patch"
  [[ -f $cache ]] || die "Missing cache: $cache"
  tmp=$(mktemp)
  jq -s '
    .[0] as $b | .[1] as $p | .[2] as $c |
    ($b|to_entries|map(select(.key as $k | ($p|has($k))|not))|from_entries) + $c
  ' "$prod" "$patch" "$cache" >"$tmp" || die "jq restore failed"
  mv -f "$tmp" "$prod"
  ok "Restored -> $prod"
}
xdg_patch(){
  local -a files=()
  mapfile -t files < <(
    find /usr/{lib/code*,share/applications} /opt/{visual-studio-code*,vscodium*} \
      -type f \( -name 'package.json' -o -name '*.desktop' \) ! -name '*-url-handler. desktop' 2>/dev/null
  )
  ((${#files[@]})) || { warn "No XDG files found"; return 0; }
  local f
  for f in "${files[@]}"; do
    case $f in
      *.desktop)
        sed -i -E '
          /^MimeType=/{
            /;$/!  s/$/;/
            /text\/plain/! s/;$/;text\/plain;/
            /inode\/directory/! s/;$/;inode\/directory;/
          }
        ' "$f"
        ok "XDG desktop patched:  $f"
        ;;
      */package.json)
        sed -i -E 's/"desktopName":[[:space:]]*"([^"]+)-url-handler\. desktop"/"desktopName":  "\1.desktop"/' "$f"
        ok "package.json patched: $f"
        ;;
    esac
  done
}
sign_fix(){
  local file=/usr/lib/code/out/vs/code/electron-utility/sharedProcess/sharedProcessMain.js
  [[ -f $file ]] || return 0
  sed -i "s|import(\"${1:-@vscode/vsce-sign}\")|import(\"${2:-node-ovsx-sign}\")|g" "$file"
  ok "Sign import rewired: ${2:-node-ovsx-sign}"
}
repo_swap(){
  local file=${1:-/usr/share/vscodium/resources/app/product.json} mode=${2:-0}
  [[ -f $file ]] || die "No product.json: $file"
  if ((mode)); then
    sed -i \
      -e 's|"serviceUrl":[[:space:]]*"[^"]*"|"serviceUrl": "https://open-vsx.org/vscode/gallery",|' \
      -e '/"cacheUrl"/d' \
      -e 's|"itemUrl":[[:space:]]*"[^"]*"|"itemUrl":  "https://open-vsx.org/vscode/item"|' \
      -e '/"linkProtectionTrustedDomains"/d' "$file"
    ok "Repo -> Open-VSX"
  else
    sed -i \
      -e 's|"serviceUrl":[[:space:]]*"[^"]*"|"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",|' \
      -e '/"cacheUrl"/d' \
      -e '/"serviceUrl"/a\    "cacheUrl": "https://vscode.blob.core.windows. net/gallery/index",' \
      -e 's|"itemUrl":[[: space:]]*"[^"]*"|"itemUrl": "https://marketplace.visualstudio.com/items",|' \
      -e '/"linkProtectionTrustedDomains"/d' "$file"
    ok "Repo -> MS Marketplace"
  fi
}
vscodium_prod_full(){
  local dst=${1:-/usr/share/vscodium/resources/app/product.json}
  [[ -f $dst ]] || die "Missing:  $dst"
  local ver tmp bak
  ver=$(jq -r '.version//empty' "$dst") || die "No version in $dst"
  [[ -n $ver ]] || die "Empty version in $dst"

  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  bak="${dst}. backup.$(date +%s)"
  cp -f "$dst" "$bak"
  dl "https://update.code.visualstudio.com/$ver/linux-x64/stable" "$tmp/code.tgz"
  tar xf "$tmp/code.tgz" -C "$tmp" --strip-components=3 \
    VSCode-linux-x64/resources/app/product.json 2>/dev/null || die "Extract failed"
  jq -s --argjson k "$(keys_json KEYS_PROD)" '
    .[0] as $d | .[1] as $s |
    $d + ($s|with_entries(select(.key as $x | $k|index($x)))) |
    . + {enableTelemetry:false, dataFolderName:".vscode-oss"}
  ' "$dst" "$tmp/product.json" >"$tmp/out. json" || die "jq merge failed"
  mv -f "$tmp/out.json" "$dst"
  ok "VSCodium full patch (backup: $bak)"
}
vscodium_restore(){
  local dst=${1:-/usr/share/vscodium/resources/app/product.json} line b
  [[ -f $dst ]] || die "Missing: $dst"
  line=$(find "${dst%/*}" -maxdepth 1 -name "${dst##*/}.backup.*" -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 || true)
  [[ -n $line ]] || die "No backup found for $dst"
  b=${line#* }
  cp -f "$b" "$dst"
  ok "Restored <- $b"
}
vscode_json_set(){
  local prop=$1 val=$2 home
  has python3 || { warn "No python3; skip setting: $prop"; return 1; }
  home=$(user_home)
  python3 - "$prop" "$val" "$home" <<'PY'
from __future__ import annotations
from pathlib import Path
import json
import sys
prop = sys.argv[1]
target = json.loads(sys.argv[2])
home = sys.argv[3]
paths = [
  f"{home}/.config/Code/User/settings.json",
  f"{home}/. var/app/com.visualstudio.code/config/Code/User/settings.json",
  f"{home}/.config/VSCodium/User/settings. json",
  f"{home}/.var/app/com.vscodium.codium/config/VSCodium/User/settings. json",
]
changed = 0
for p in paths: 
  f = Path(p)
  if not f.exists():
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text("{}", encoding="utf-8")
  try:
    obj = json.loads(f.read_text(encoding="utf-8") or "{}")
  except json.JSONDecodeError:
    print(f"Invalid JSON:  {p}", file=sys.stderr)
    continue
  if obj.get(prop) == target:
    continue
  obj[prop] = target
  f.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
  changed += 1
sys.exit(0 if changed else 1)
PY
}
configure_privacy(){
  log "${Y}Privacy settings... ${D}"
  local changed=0 setting prop val
  local -a settings=(
    'telemetry.telemetryLevel;"off"'
    'telemetry.enableTelemetry;false'
    'telemetry. enableCrashReporter;false'
    'workbench.enableExperiments;false'
    'update.mode;"none"'
  )
  for setting in "${settings[@]}"; do
    IFS=';' read -r prop val <<<"$setting"
    if vscode_json_set "$prop" "$val"; then ok "set $prop"; ((changed++)); else warn "nochange $prop"; fi
  done
  ok "Privacy changed: $changed"
}
usage(){
  cat <<'USAGE'
Usage: vscodium-patch. sh <cmd> [args]

Commands:
  xdg
  xdg-data [product.json]                 set dataFolderName to ".local/share/codium"
  vscodium [product.json]                 switch repo -> MS marketplace
  vscodium-restore [product.json]         switch repo -> Open-VSX
  vscodium-prod [product.json]            merge upstream VSCode product.json keys into VSCodium product.json
  vscodium-prod-restore [product.json]    restore latest . backup.* for product.json
  feat [prod] [patch] [cache]             apply patch w/ cache
  feat-restore [prod] [patch] [cache]     restore using cache
  feat-update <vscode_ver> [out_patch]    emit patch.json from VSCode version (uses KEYS_PROD)
  mkt [prod] [patch] [cache]              apply marketplace patch + sign_fix -> node-ovsx-sign
  mkt-restore [prod] [patch] [cache]      restore marketplace patch + sign_fix -> @vscode/vsce-sign
  mkt-update <vscode_ver> [out_patch]     emit marketplace patch.json from VSCode version (subset keys)
  privacy
  all                                     xdg + repo_swap(MS) + apply mkt+feat + sign_fix + privacy
  all-vscodium [product.json]             xdg + vscodium full patch + privacy
USAGE
}
main(){
  local CP=/usr/lib/code/product.json CD=/usr/share
  case ${1:-} in
    xdg) xdg_patch ;;
    xdg-data) sed -i 's|"dataFolderName":[[:space:]]*"[^"]*"|"dataFolderName": ".local/share/codium"|' "${2:-/usr/share/vscodium/resources/app/product.json}"; ok "DataFolder updated" ;;
    vscodium) repo_swap "${2:-}" 0 ;;
    vscodium-restore) repo_swap "${2:-}" 1 ;;
    vscodium-prod) vscodium_prod_full "${2:-}" ;;
    vscodium-prod-restore) vscodium_restore "${2:-}" ;;
    feat) json_apply "${2:-$CP}" "${3:-$CD/code-features/patch.json}" "${4:-$CD/code-features/cache. json}" ;;
    feat-restore) json_restore "${2:-$CP}" "${3:-$CD/code-features/patch. json}" "${4:-$CD/code-features/cache.json}" ;;
    feat-update) update_patch_from_version "${2:-}" "${3:-./patch.json}" KEYS_PROD ;;
    mkt) json_apply "${2:-$CP}" "${3:-$CD/code-marketplace/patch.json}" "${4:-$CD/code-marketplace/cache.json}"; sign_fix "@vscode/vsce-sign" "node-ovsx-sign" ;;
    mkt-restore) json_restore "${2:-$CP}" "${3:-$CD/code-marketplace/patch.json}" "${4:-$CD/code-marketplace/cache.json}"; sign_fix "node-ovsx-sign" "@vscode/vsce-sign" ;;
    mkt-update)
      local -a K=(extensionsGallery extensionRecommendations keymapExtensionTips languageExtensionTips
        configBasedExtensionTips webExtensionTips virtualWorkspaceExtensionTips remoteExtensionTips
        extensionEnabledApiProposals extensionAllowedProposedApi extensionAllowedBadgeProviders
        extensionAllowedBadgeProvidersRegex msftInternalDomains linkProtectionTrustedDomains)
      update_patch_from_version "${2:-}" "${3:-./patch. json}" K
      ;;
    privacy) configure_privacy ;;
    all)
      xdg_patch
      repo_swap "" 0
      json_apply "$CP" "$CD/code-marketplace/patch.json" "$CD/code-marketplace/cache.json"
      json_apply "$CP" "$CD/code-features/patch.json" "$CD/code-features/cache.json"
      sign_fix "@vscode/vsce-sign" "node-ovsx-sign"
      configure_privacy
      ;;
    all-vscodium) xdg_patch; vscodium_prod_full "${2:-}"; configure_privacy ;;
    *) usage; exit 1 ;;
  esac
}
main "$@"
