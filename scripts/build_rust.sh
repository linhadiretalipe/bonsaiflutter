#!/bin/bash
# Quick Rust build only (no bridge regeneration)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUST_DIR="$(dirname "$SCRIPT_DIR")/rust"

export ANDROID_NDK_HOME="$HOME/Library/Android/sdk/ndk/25.1.8937393"

echo "🦀 Compiling Rust..."
cd "$RUST_DIR"
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release

echo "✅ Rust compiled!"
echo "⚠️  Don't forget: flutter_rust_bridge_codegen generate"

cd ..
flutter_rust_bridge_codegen generate