export CFLAGS+=' -ffat-lto-objects'
export LDFLAGS+=' -lzstd'
cargo install sccache --locked --features dist-server,native-zlib,unstable --no-default-features
