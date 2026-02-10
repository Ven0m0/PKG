with open('pkg.sh', 'r') as f:
    lines = f.readlines()

patch_arch_def = [
    '\n',
    'patch_arch() {\n',
    '  local -a targets=("")\n',
    '  # Optimization: only patch if enabled and targets exist\n',
    '  [[ 1 == 1 ]] || return 0\n',
    '  ((0)) || return 0\n',
    '\n',
    '  local -a files=()\n',
    '  for pkg in ""; do\n',
    '    [[ -f "/PKGBUILD" ]] && files+=("/PKGBUILD")\n',
    '  done\n',
    '\n',
    '  ((0)) || return 0\n',
    '\n',
    '  printf \'%s\0\' "" | \\n',
    '    { xargs -0 grep -Z -l -e "arch=(x86_64)" -e "arch=(\'x86_64\')" || true; } | \\n',
    '    xargs -0 -r sed -i -e "s/arch=(x86_64)/arch=(x86_64_v3)/" \\n',
    '      -e "s/arch=(\'x86_64\')/arch=(\'x86_64_v3\')/"\n',
    '}\n'
]

final_lines = []
in_find_pkgs = False
skipping_patch = False
in_cmd_build = False
added_config = False

for line in lines:
    stripped = line.strip()

    # 1. Config
    if line.startswith('DIST_MODE=') and not added_config:
        final_lines.append(line)
        final_lines.append('PATCH_ARCH=1\n')
        added_config = True
        continue

    # 2. find_pkgs
    if line.startswith('find_pkgs() {'):
        in_find_pkgs = True
        final_lines.append(line)
        continue

    if in_find_pkgs:
        if line.startswith('}'):
            in_find_pkgs = False
            final_lines.append(line)
            # Insert new function definition after find_pkgs
            final_lines.extend(patch_arch_def)
            continue

        if 'local -a files=()' in stripped:
            continue
        if 'files+=("")' in stripped:
            continue

        if '# Patch arch for x86_64_v3' in stripped:
            skipping_patch = True
            continue # Skip this line

        if skipping_patch:
            # We are inside the patch block.
            # The block ends with a 'fi'.
            # We must be careful not to skip other 'fi's, but there are no nested ifs in that block.
            if stripped == 'fi':
                skipping_patch = False
            continue

        final_lines.append(line)
        continue

    # 3. cmd_build
    if line.startswith('cmd_build() {'):
        in_cmd_build = True
        final_lines.append(line)
        continue

    if in_cmd_build:
        # Looking for the log line to insert before or after
        if 'log "Building 0 package(s)' in line:
            # Insert before the log
            final_lines.append('  patch_arch ""\n')
            final_lines.append(line)
            in_cmd_build = False # Stop looking inside cmd_build
            continue

        # Also need to handle if 'cmd_build' ends without finding it (unlikely)
        if line.startswith('}'):
            in_cmd_build = False

    final_lines.append(line)

with open('pkg.sh', 'w') as f:
    f.writelines(final_lines)
