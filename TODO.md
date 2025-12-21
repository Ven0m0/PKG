# TODO

## Planned Features

- [ ] [AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages) - Create AppImages for compatibility across Arch, Debian, and Termux
- [ ] [tkg-patches](https://github.com/Frogging-Family/community-patches) - Integrate and autofetch
- [ ] [archlinux-pkgs-debloated](https://github.com/Ven0m0/archlinux-pkgs-debloated)

## Package Improvements

- [ ] Add more optimized PKGBUILDs
- [ ] Improve build documentation

## References

- [pkgforge-dev/Anylinux-AppImages](https://github.com/pkgforge-dev/Anylinux-AppImages)
- [Frogging-Family](https://github.com/Frogging-Family/community-patches)



### TODO

```bash
PKG_FORMAT="zst"
COMPRESS=(zstd -c -z -q -)

# ensure all elements of the package have the same mtime
	find . -exec touch -h -d @$SOURCE_DATE_EPOCH {} +
# Create package
	shopt -s dotglob globstar
	printf '%s\0' **/* | bsdtar -cnf - --format=mtree \
		--options='!all,use-set,type,uid,gid,mode,time,size,md5,sha256,link' \
		--null --files-from - --exclude .MTREE | \
		gzip -c -f -n > .MTREE
	touch -d @$SOURCE_DATE_EPOCH .MTREE
	printf '%s\0' **/* | bsdtar --no-fflags -cnf - --null --files-from - | \
		$COMPRESS > "$PACMAN_FILE"
	shopt -u dotglob globstar

termux_step_elf_cleaner() {
	termux_step_elf_cleaner__from_paths . \( -path "./bin/*" -o -path "./lib/*" -o -path "./lib32/*" -o -path "./libexec/*" -o -path "./opt/*" \)
}

termux_step_elf_cleaner__from_paths() {
	# Remove entries unsupported by Android's linker:
	find "$@" -type f -print0 | xargs -r -0 \
		"$TERMUX_ELF_CLEANER" --api-level "$TERMUX_PKG_API_LEVEL"
}
termux_step_strip_elf_symbols() {
	termux_step_strip_elf_symbols__from_paths . \( -path "./bin/*" -o -path "./lib/*" -o -path "./lib32/*" -o -path "./libexec/*" \)
}

termux_step_strip_elf_symbols__from_paths() {
	# Strip binaries. file(1) may fail for certain unusual files, so disable pipefail.
	(
		set +e +o pipefail && \
		find "$@" -type f -print0 | xargs -r -0 \
			file | grep -E "ELF .+ (executable|shared object)" | cut -f 1 -d : |
			xargs -r "$STRIP" --strip-unneeded --preserve-dates
	)
}
termux_step_cleanup_packages() {
	[[ "${TERMUX_CLEANUP_BUILT_PACKAGES_ON_LOW_DISK_SPACE:=false}" == "true" ]] || return 0
	[[ -d "$TERMUX_TOPDIR" ]] || return 0

	local AVAILABLE TERMUX_PACKAGES_DIRECTORIES PKGS PKG_REGEX

	# Extract available disk space in bytes
	AVAILABLE="$(df "$TERMUX_TOPDIR" | awk 'NR==2 {print $4 * 1024}')"

	# No need to cleanup if there is enough disk space
	(( AVAILABLE <= TERMUX_CLEANUP_BUILT_PACKAGES_THRESHOLD )) || return 0

	TERMUX_PACKAGES_DIRECTORIES="$(jq --raw-output 'del(.pkg_format) | keys | .[]' "${TERMUX_SCRIPTDIR}"/repo.json)"

	# Build package name regex to be used with `find`, avoiding loops.
	PKGS="$(find ${TERMUX_PACKAGES_DIRECTORIES} -mindepth 1 -maxdepth 1 -type d -printf '%f\n')"
	[[ -z "$PKGS" ]] && return 0

	# Exclude current package from the list.
	PKGS="$(printf "%s" "$PKGS" | grep -Fxv "$TERMUX_PKG_NAME")"
	[[ -z "$PKGS" ]] && return 0

	PKG_REGEX="$(printf "%s" "$PKGS" | sed -zE 's/[][\.|$(){}?+*^]/\\&/g' | sed -E 's/(.*)/(\1)/g' | sed -zE -e 's/[\n]+/|/g' -e 's/(.*)/(\1)/g')"

	echo "INFO: cleaning up some disk space for building \"${TERMUX_PKG_NAME}\"."

	(cd "$TERMUX_TOPDIR" && find . -mindepth 1 -maxdepth 1 -type d -regextype posix-extended -regex "^\./$PKG_REGEX$" -exec rm -rf "{}" +)
}

```
