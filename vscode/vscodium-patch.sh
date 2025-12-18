#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
shopt -s nullglob globstar
export LC_ALL=C

# ═══════════════════════════════════════════════════════════════════════════
# VSCodium Patch Script - Product.json Manipulation & Marketplace Switching
# ═══════════════════════════════════════════════════════════════════════════

# ─── Color Helpers ─────────────────────────────────────────────────────────
readonly R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' D=$'\e[0m'
warn(){ printf '%b\n' "${Y}WARN:${D} $*" >&2; }
die(){ printf '%b\n' "${R}ERR:${D} $*" >&2; exit "${2:-1}"; }
ok(){ printf '%b\n' "${G}✓${D} $*"; }
has(){ command -v "$1" &>/dev/null; }

# ─── JSON Tool Detection ───────────────────────────────────────────────────
if has jaq; then
  readonly JQ=jaq
elif has jq; then
  readonly JQ=jq
else
  die "Need jq or jaq for JSON manipulation"
fi

# ─── Keys for Migration ────────────────────────────────────────────────────
readonly KEYS_PROD=(
  nameShort nameLong applicationName dataFolderName serverDataFolderName
  darwinBundleIdentifier linuxIconName licenseUrl extensionAllowedProposedApi
  extensionEnabledApiProposals extensionKind extensionPointExtensionKind
  extensionSyncedKeys extensionVirtualWorkspacesSupport extensionsGallery
  extensionTips extensionImportantTips exeBasedExtensionTips
  configBasedExtensionTips keymapExtensionTips languageExtensionTips
  remoteExtensionTips webExtensionTips virtualWorkspaceExtensionTips
  trustedExtensionAuthAccess trustedExtensionUrlPublicKeys auth
  configurationSync "configurationSync.store" editSessions "editSessions.store"
  settingsSync aiConfig commandPaletteSuggestedCommandIds
  extensionRecommendations extensionKeywords extensionAllowedBadgeProviders
  extensionAllowedBadgeProvidersRegex linkProtectionTrustedDomains
  msftInternalDomains documentationUrl introductoryVideosUrl
  tipsAndTricksUrl newsletterSignupUrl releaseNotesUrl
  keyboardShortcutsUrlMac keyboardShortcutsUrlLinux keyboardShortcutsUrlWin
  quality settingsSearchUrl tasConfig tunnelApplicationName
  tunnelApplicationConfig serverApplicationName serverGreeting urlProtocol
  webUrl webEndpointUrl webEndpointUrlTemplate
  webviewContentExternalBaseUrlTemplate builtInExtensions
  extensionAllowedExtensionKinds crash aiRelatedInformationUrl defaultChatAgent
)

# ─── Download Helper ───────────────────────────────────────────────────────
dl(){
  local url="$1" output="$2"
  mkdir -p "${output%/*}"

  if has aria2c; then
    aria2c -q --max-tries=3 --retry-wait=1 -d "${output%/*}" -o "${output##*/}" "$url"
  elif has curl; then
    curl -fsSL --retry 3 --http2 --tlsv1.2 "$url" -o "$output"
  elif has wget; then
    wget -qO "$output" "$url"
  else
    die "Need aria2c/curl/wget for downloads"
  fi
}

# ─── XDG Desktop File Patching ─────────────────────────────────────────────
xdg_patch(){
  while IFS= read -r f; do
    case "$f" in
      *.desktop)
        # Add MIME types if missing (consolidated sed operations)
        if ! grep -q "text/plain" "$f" || ! grep -q "inode/directory" "$f"; then
          sed -i -E '
            /^MimeType=.*[^;]$/ s/$/;/
            /^MimeType=/ {
              /text\/plain/! s/;$/;text\/plain;/
              /inode\/directory/! s/;$/;inode\/directory;/
            }
          ' "$f"
        fi
        ;;
      */package.json)
        sed -i -E 's/"desktopName":[[:space:]]*"(.+)-url-handler\.desktop"/"desktopName": "\1.desktop"/' "$f"
        ;;
    esac
    ok "$f"
  done
}

find_files(){
  printf '%s\n' \
    /usr/lib/code*/package.json \
    /opt/visual-studio-code*/resources/app/package.json \
    /opt/vscodium*/resources/app/package.json \
    /usr/share/applications/{code,vscode,vscodium}*.desktop \
    | grep -vE '\-url-handler.desktop$'
}

# ─── JSON Operations ───────────────────────────────────────────────────────
apply_json(){
  local prod="$1" patch="$2" cache="$3" tmp

  [[ ! -f "$prod" ]] && { warn "$prod missing"; return 0; }
  [[ ! -f "$patch" ]] && die "Patch missing: $patch"
  [[ ! -f "$cache" ]] && echo '{}' > "$cache"

  tmp="$prod.tmp.$$"
  "$JQ" -s '
    .[0] as $b | .[1] as $p |
    ($b | to_entries | map(select(.key as $k | $p | has($k))) | from_entries) as $c |
    ($b + $p) | {p: ., c: $c}
  ' "$prod" "$patch" > "$tmp" || return 1

  "$JQ" -r .p "$tmp" > "$prod" &&
  "$JQ" -r .c "$tmp" > "$cache" &&
  rm "$tmp" &&
  ok "Applied to $prod"
}

restore_json(){
  local prod="$1" patch="$2" cache="$3" tmp

  [[ ! -f "$prod" || ! -f "$cache" ]] && die "Files missing for $prod"

  tmp="$prod.tmp.$$"
  "$JQ" -s '
    .[0] as $b | .[1] as $p | .[2] as $c |
    ($b | to_entries | map(select(.key as $k | ($p | has($k)) | not)) | from_entries) + $c
  ' "$prod" "$patch" "$cache" > "$tmp" || return 1

  mv "$tmp" "$prod" && ok "Restored $prod"
}

update_json(){
  local ver="$1" out_patch="$2" work="/tmp/code-up.$$"
  local url="https://update.code.visualstudio.com/${ver}/linux-x64/stable"
  local -n kref="$3"

  [[ -z "$ver" ]] && die "Version required"

  echo "⬇ VSCode $ver..."
  dl "$url" "$work/c.tgz" || { rm -rf "$work"; return 1; }

  tar xf "$work/c.tgz" -C "$work" --strip-components=3 \
    VSCode-linux-x64/resources/app/product.json

  "$JQ" -r --argjson k "$(printf '%s\n' "${kref[@]}" | "$JQ" -R . | "$JQ" -s .)" '
    reduce $k[] as $x ({}; . + {($x): (getpath($x | split("."))?)}) |
    . + {enableTelemetry: false}
  ' "$work/product.json" > "$out_patch"

  rm -rf "$work"
  ok "Updated $out_patch"

  if [[ -f ./PKGBUILD ]] && has updpkgsums; then
    updpkgsums ./PKGBUILD || true
  fi
}

# ─── VSCodium-Specific Operations ──────────────────────────────────────────
sign_fix(){
  local from="${1:-@vscode/vsce-sign}" to="${2:-node-ovsx-sign}"
  local file="/usr/lib/code/out/vs/code/electron-utility/sharedProcess/sharedProcessMain.js"

  [[ -f "$file" ]] && sed -i "s|import(\"${from}\")|import(\"${to}\")|g" "$file"
}

repo_swap(){
  local file="${1:-/usr/share/vscodium/resources/app/product.json}"
  local mode="${2:-0}"

  [[ ! -f "$file" ]] && die "No product.json at $file"

  if [[ "$mode" -eq 1 ]]; then
    # Switch to Open-VSX
    sed -i \
      -e 's|"serviceUrl":.*|"serviceUrl": "https://open-vsx.org/vscode/gallery",|' \
      -e '/"cacheUrl/d' \
      -e 's|"itemUrl":.*|"itemUrl": "https://open-vsx.org/vscode/item"|' \
      -e '/"linkProtectionTrustedDomains/d' \
      -e '/"documentationUrl/i\  "linkProtectionTrustedDomains": ["https://open-vsx.org"],' \
      "$file"
    ok "Repo: Open-VSX"
  else
    # Switch to MS Marketplace
    sed -i \
      -e 's|"serviceUrl":.*|"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",|' \
      -e '/"cacheUrl/d' \
      -e '/"serviceUrl/a\    "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",' \
      -e 's|"itemUrl":.*|"itemUrl": "https://marketplace.visualstudio.com/items"|' \
      -e '/"linkProtectionTrustedDomains/d' \
      "$file"
    ok "Repo: MS Marketplace"
  fi
}

vscodium_prod_full(){
  local dst="${1:-/usr/share/vscodium/resources/app/product.json}"
  local work="/tmp/vp.$$" ver src

  [[ ! -f "$dst" ]] && die "Missing $dst"

  ver=$("$JQ" -r '.version // empty' "$dst") || die "No version in product.json"
  src="${work}/product.json"

  cp "$dst" "${dst}.backup.$(date +%s)"
  dl "https://update.code.visualstudio.com/$ver/linux-x64/stable" "${work}/c.tgz"

  tar xf "${work}/c.tgz" -C "$work" --strip-components=3 \
    VSCode-linux-x64/resources/app/product.json

  "$JQ" -s --argjson k "$(printf '%s\n' "${KEYS_PROD[@]}" | "$JQ" -R . | "$JQ" -s .)" '
    .[0] as $d | .[1] as $s |
    $d + ($s | with_entries(select(.key as $x | $k | index($x)))) |
    . + {enableTelemetry: false}
  ' "$dst" "$src" > "${dst}.tmp" && mv "${dst}.tmp" "$dst"

  sed -i 's|"dataFolderName": ".*"|"dataFolderName": ".local/share/codium"|' "$dst"

  rm -rf "$work"
  ok "✓ Patched VSCodium Full"
}

vscodium_restore(){
  local dst="${1:-/usr/share/vscodium/resources/app/product.json}"
  local backup

  backup=$(find "${dst%/*}" -maxdepth 1 -name "${dst##*/}.backup.*" -printf "%T@ %p\n" \
    | sort -rn | head -1 | cut -d' ' -f2-)

  [[ -z "$backup" ]] && die "No backup found"

  cp -f "$backup" "$dst" && ok "✓ Restored $backup"
}

# ─── Main Entry Point ──────────────────────────────────────────────────────
main(){
  local C_P="/usr/lib/code/product.json"
  local C_DIR="/usr/share"

  case "${1:-}" in
    xdg)
      find_files | xdg_patch
      ;;
    xdg-data)
      local f="${2:-/usr/share/vscodium/resources/app/product.json}"
      sed -i 's|"dataFolderName": ".*"|"dataFolderName": ".local/share/codium"|' "$f"
      ok "DataFolder updated"
      ;;
    vscodium)
      repo_swap "${2:-}" 0
      ;;
    vscodium-restore)
      repo_swap "${2:-}" 1
      ;;
    vscodium-prod)
      vscodium_prod_full "${2:-}"
      ;;
    vscodium-prod-restore)
      vscodium_restore "${2:-}"
      ;;
    feat)
      apply_json \
        "${2:-$C_P}" \
        "${3:-$C_DIR/code-features/patch.json}" \
        "${4:-$C_DIR/code-features/cache.json}"
      ;;
    feat-restore)
      restore_json \
        "${2:-$C_P}" \
        "${3:-$C_DIR/code-features/patch.json}" \
        "${4:-$C_DIR/code-features/cache.json}"
      ;;
    feat-update)
      update_json "${2:-}" "${3:-./patch.json}" KEYS_PROD
      ;;
    mkt)
      apply_json \
        "${2:-$C_P}" \
        "${3:-$C_DIR/code-marketplace/patch.json}" \
        "${4:-$C_DIR/code-marketplace/cache.json}"
      sign_fix node-ovsx-sign
      ;;
    mkt-restore)
      restore_json \
        "${2:-$C_P}" \
        "${3:-$C_DIR/code-marketplace/patch.json}" \
        "${4:-$C_DIR/code-marketplace/cache.json}"
      sign_fix
      ;;
    mkt-update)
      local K=(
        extensionsGallery extensionRecommendations keymapExtensionTips
        languageExtensionTips configBasedExtensionTips webExtensionTips
        virtualWorkspaceExtensionTips remoteExtensionTips
        extensionAllowedBadgeProviders extensionAllowedBadgeProvidersRegex
        msftInternalDomains linkProtectionTrustedDomains
      )
      update_json "${2:-}" "${3:-./patch.json}" K
      ;;
    all)
      find_files | xdg_patch
      repo_swap "" 0
      apply_json "$C_P" "$C_DIR/code-marketplace/patch.json" \
        "$C_DIR/code-marketplace/cache.json"
      apply_json "$C_P" "$C_DIR/code-features/patch.json" \
        "$C_DIR/code-features/cache.json"
      sign_fix node-ovsx-sign
      ;;
    all-vscodium)
      find_files | xdg_patch
      vscodium_prod_full "${2:-}"
      ;;
    *)
      cat <<'USAGE'
Usage: vscodium-patch.sh <command> [args]

Commands:
  xdg                      Patch XDG desktop files
  xdg-data [file]          Update dataFolderName
  vscodium [file]          Switch to MS Marketplace
  vscodium-restore [file]  Switch to Open-VSX
  vscodium-prod [file]     Full VSCodium product.json patch
  vscodium-prod-restore    Restore from backup
  feat [prod] [patch] [cache]         Apply features patch
  feat-restore [prod] [patch] [cache] Restore features
  feat-update <ver> [out]             Update features patch
  mkt [prod] [patch] [cache]          Apply marketplace patch
  mkt-restore [prod] [patch] [cache]  Restore marketplace
  mkt-update <ver> [out]              Update marketplace patch
  all                      Apply all patches
  all-vscodium [file]      Apply all VSCodium patches
USAGE
      exit 1
      ;;
  esac
}

main "$@"
