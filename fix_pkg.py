import sys

with open('pkg.sh', 'r') as f:
    lines = f.readlines()

new_lines = []
patch_arch_def = [
    '\n',
    'patch_arch() {\n',
    '  local -a targets=("${@}")\n',
    '  # Optimization: only patch if enabled and targets exist\n',
    '  [[ ${PATCH_ARCH:-1} == 1 ]] || return 0\n',
    '  ((${#targets[@]})) || return 0\n',
    '\n',
    '  local -a files=()\n',
    '  for pkg in "${targets[@]}"; do\n',
    '    [[ -f "$pkg/PKGBUILD" ]] && files+=("$pkg/PKGBUILD")\n',
    '  done\n',
    '\n',
    '  ((${#files[@]})) || return 0\n',
    '\n',
    '  printf \'%s\\0\' "${files[@]}" | \\\n',
    '    { xargs -0 grep -Z -l -e "arch=(x86_64)" -e "arch=(\'x86_64\')" || true; } | \\\n',
    '    xargs -0 -r sed -i -e "s/arch=(x86_64)/arch=(x86_64_v3)/" \\\n',
    '      -e "s/arch=(\'x86_64\')/arch=(\'x86_64_v3\')/"\n',
    '}\n'
]

in_find_pkgs = False
in_bad_patch_arch = False
in_cmd_build = False
fixed_config = False
inserted_patch_arch_call = False

for line in lines:
    stripped = line.strip()

    # 1. Config Fix
    if line.startswith('PATCH_ARCH=1'):
        continue
    if line.startswith('DIST_MODE=') and not fixed_config:
        new_lines.append(line)
        new_lines.append('PATCH_ARCH=${PATCH_ARCH:-1}\n')
        fixed_config = True
        continue

    # 2. find_pkgs Fix
    if line.startswith('find_pkgs() {'):
        in_find_pkgs = True
        new_lines.append(line)
        continue

    if in_find_pkgs:
        if line.startswith('}'):
            in_find_pkgs = False
            new_lines.append(line)
            # Append correct patch_arch here
            new_lines.extend(patch_arch_def)
            continue

        # Remove leftover 'files+=("$f")'
        if 'files+=("$f")' in line:
            continue

        # Remove any lingering patch block
        if '# Patch arch for x86_64_v3' in line:
             # Just skip this line.
             # And skip next lines?
             # But assume previous attempt removed it?
             # Let's rely on content matching.
             # If previous attempt removed it, this line won't exist.
             continue
        if line.strip().startswith('if ((${#files[@]} > 0)); then'): continue
        if 'grep -Z -l -e "arch=(x86_64)"' in line: continue
        if 'sed -i -e "s/arch=(x86_64)' in line: continue
        # The 'fi' might be tricky if indentation varies.
        # But if previous run removed them, we are good.

        new_lines.append(line)
        continue

    # 3. Remove bad patch_arch blocks
    if line.startswith('patch_arch() {'):
        in_bad_patch_arch = True
        continue

    if in_bad_patch_arch:
        if line.startswith('}'):
            in_bad_patch_arch = False
        continue

    # 4. cmd_build Fix
    if line.startswith('cmd_build() {'):
        in_cmd_build = True
        new_lines.append(line)
        continue

    if in_cmd_build:
        if line.startswith('}'):
             in_cmd_build = False

        if 'log "Building ${#targets[@]} package(s)' in line:
            if not inserted_patch_arch_call:
                new_lines.append('  patch_arch "${targets[@]}"\n')
                inserted_patch_arch_call = True
            new_lines.append(line)
            continue

        new_lines.append(line)
        continue

    new_lines.append(line)

with open('pkg.sh', 'w') as f:
    f.writelines(new_lines)
