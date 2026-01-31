#!/bin/bash
# Bonsai Mobile - Full Rebuild Script
# Compiles Rust and regenerates Flutter bridge

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RUST_DIR="$PROJECT_ROOT/rust"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔨 Building Bonsai Mobile...${NC}"

# Check NDK
NDK_PATH="$HOME/Library/Android/sdk/ndk/25.1.8937393"
if [ ! -d "$NDK_PATH" ]; then
    echo "❌ NDK 25.1.8937393 not found at $NDK_PATH"
    echo "Please install via: sdkmanager 'ndk;25.1.8937393'"
    exit 1
fi

export ANDROID_NDK_HOME="$NDK_PATH"

# Step 1: Compile Rust
echo -e "${GREEN}[1/3] Compiling Rust for Android arm64...${NC}"
cd "$RUST_DIR"
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release

# Step 2: Regenerate Flutter bridge
echo -e "${GREEN}[2/3] Regenerating Flutter-Rust bridge...${NC}"
cd "$PROJECT_ROOT"
flutter_rust_bridge_codegen generate

# Step 3: Get Flutter dependencies
echo -e "${GREEN}[3/3] Getting Flutter packages...${NC}"
flutter pub get

echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "To run the app:"
echo "  flutter run"
