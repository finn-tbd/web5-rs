set shell := ["bash", "-uc"]

# Setup local development environment
setup:
  #!/bin/bash
  source bin/activate-hermit
  if [ ! -d ".git/modules/web5-spec" ]; then
    git submodule update --init --recursive
  fi
  if [[ "$(cargo 2>&1)" == *"rustup could not choose a version of cargo to run"* ]]; then
    rustup default 1.74.0
    rustup target add aarch64-apple-darwin
  fi

docs: setup
  cargo doc --open --no-deps

build: setup
  cargo build --workspace

test: setup
  cargo test --workspace

lint: setup
  cargo clippy --workspace
  cargo fmt

bind: setup
  just bind-kotlin

bind-kotlin: setup
  mkdir -p bound/kt/src/main/resources
  cargo build --release --package web5_uniffi --target aarch64-apple-darwin
  cp target/aarch64-apple-darwin/release/libweb5_uniffi.dylib \
    bound/kt/src/main/resources/libweb5_uniffi_aarch64_apple_darwin.dylib
  cargo run --package web5_uniffi \
    --bin uniffi-bindgen \
    generate --library bound/kt/src/main/resources/libweb5_uniffi_aarch64_apple_darwin.dylib \
    --language kotlin \
    --out-dir target/bindgen-kotlin
  sed -i '' 's/findLibraryName(componentName)/detectSystemTarget()/' target/bindgen-kotlin/web5/sdk/rust/web5.kt
  cp target/bindgen-kotlin/web5/sdk/rust/web5.kt bound/kt/src/main/kotlin/web5/sdk/rust/UniFFI.kt

test-bound: setup
  just test-kotlin

test-kotlin: setup
  cd bound/kt && mvn clean test
