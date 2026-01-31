# Bonsai Mobile - Build Documentation

## Prerequisites

### Required Tools
- **Flutter SDK** (3.x or later)
- **Rust** (`rustup` with nightly toolchain)
- **Android NDK** version **25.1.8937393** (NDK 29 has compatibility issues)
- **cargo-ndk**: `cargo install cargo-ndk`
- **flutter_rust_bridge_codegen**: `cargo install flutter_rust_bridge_codegen`

### Android NDK Setup
```bash
# Install NDK 25 via Android Studio SDK Manager
# Or via command line:
sdkmanager "ndk;25.1.8937393"
```

---

## Build Process

### 1. Compile Rust for Android
```bash
cd rust
ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/25.1.8937393 cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
```

### 2. Regenerate Flutter-Rust Bridge
```bash
cd ..  # back to project root
flutter_rust_bridge_codegen generate
```

### 3. Run Flutter App
```bash
flutter run
```

---

## Common Issues

### Content Hash Mismatch Error
**Error:** `Content hash on Dart side is different from Rust side`

**Solution:** This happens when Rust is recompiled but Flutter uses old bindings.
1. Regenerate bridge: `flutter_rust_bridge_codegen generate`
2. Stop and restart app (don't hot restart)

### NDK Build Errors (`getentropy` or `aws-lc-sys`)
**Error:** `call to undeclared function 'getentropy'`

**Solution:** Use NDK 25 instead of NDK 29:
```bash
# Set correct NDK version
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/25.1.8937393
```

### Missing Rust Target
```bash
rustup target add aarch64-linux-android
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Build Rust | `./scripts/build_rust.sh` |
| Full rebuild | `./scripts/rebuild_all.sh` |
| Run app | `flutter run` |
