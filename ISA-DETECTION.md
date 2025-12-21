# ISA Level Detection Utility

This utility checks x86-64 microarchitecture level support on the current CPU, based on functionality from [CachyOS/cachyos-repo-add-script](https://github.com/CachyOS/cachyos-repo-add-script).

## x86-64 Microarchitecture Levels

The x86-64 instruction set has four microarchitecture levels:

- **x86-64 (v1)**: Original AMD64 baseline (2003)
- **x86-64-v2**: Adds CMPXCHG16B, LAHF-SAHF, POPCNT, SSE3, SSE4.1, SSE4.2, SSSE3 (2009)
- **x86-64-v3**: Adds AVX, AVX2, BMI1, BMI2, F16C, FMA, LZCNT, MOVBE, XSAVE (2015)
- **x86-64-v4**: Adds AVX512F, AVX512BW, AVX512CD, AVX512DQ, AVX512VL (2017)

## Usage

### Check all ISA levels (default)

```bash
./check-isa-level.sh
# or
./check-isa-level.sh all
```

Output example:
```
ℹ Checking x86-64 microarchitecture level support...

x86-64          [NOT SUPPORTED]
x86-64-v2       [SUPPORTED]
x86-64-v3       [SUPPORTED]
x86-64-v4       [NOT SUPPORTED]

➜ Highest supported level: x86-64-v3
```

### Check specific ISA level

```bash
./check-isa-level.sh check x86-64-v3
echo $?  # 0 if supported, 1 if not supported
```

### Get highest supported level

```bash
./check-isa-level.sh highest
# Output: x86-64-v3
```

### Get recommended compiler march flag

```bash
./check-isa-level.sh march
# Output: -march=x86-64-v3
```

This can be used in build scripts:
```bash
MARCH_FLAG=$(./check-isa-level.sh march)
export CFLAGS="$CFLAGS $MARCH_FLAG -O3"
```

### Display detailed CPU information

```bash
./check-isa-level.sh cpu
```

Shows CPU model and relevant instruction set flags.

## Integration Examples

### Use in PKGBUILD

```bash
# Dynamically set march based on CPU capability
_march=$(./check-isa-level.sh march)
export CFLAGS="${CFLAGS/-O2/$_march -O3}"
export CXXFLAGS="${CXXFLAGS/-O2/$_march -O3}"
```

### Use in build scripts

```bash
# Only build if CPU supports minimum level
if ./check-isa-level.sh check x86-64-v3; then
  echo "Building with x86-64-v3 optimizations"
  export CFLAGS="$CFLAGS -march=x86-64-v3"
else
  echo "CPU does not support x86-64-v3, using baseline"
fi
```

### Source as library

```bash
source ./check-isa-level.sh

# Use functions directly
if check_supported_isa_level "x86-64-v3"; then
  echo "v3 is supported"
fi

highest=$(get_highest_isa_level)
echo "Highest level: $highest"
```

## Exit Codes

- `0` - Success (or ISA level is supported)
- `1` - Failure (or ISA level is not supported)
- `2` - Invalid usage or system error

## Requirements

- x86-64 Linux system
- Dynamic linker (`ld-linux-x86-64.so.2`) in one of:
  - `/lib/ld-linux-x86-64.so.2`
  - `/lib64/ld-linux-x86-64.so.2`
  - `/usr/lib/ld-linux-x86-64.so.2`

## References

- [x86-64 Microarchitecture levels (Wikipedia)](https://en.wikipedia.org/wiki/X86-64#Microarchitecture_levels)
- [GCC x86 Options](https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html)
- [CachyOS cachyos-repo-add-script](https://github.com/CachyOS/cachyos-repo-add-script)

## License

This utility is part of the PKG repository and follows the same license.
