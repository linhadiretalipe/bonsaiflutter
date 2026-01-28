# Bonsai Mobile - Setup Guide

Welcome to **Bonsai Mobile**! This guide will help you set up your environment and run the application, even if you are new to Flutter development.

## 0. Prerequisites

Before starting, ensure you have the following installed on your Mac or Linux:

### 1. Flutter SDK
Flutter is the framework used to build the app.
- **Install**: [Download Flutter](https://docs.flutter.dev/get-started/install)
- **Verify**: Run `flutter doctor` in your terminal to check for any missing dependencies.

### 2. Rust
The core logic of Bonsai runs on Rust.
- **Install**: Run the following command in your terminal:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```
- **Verify**: Run `cargo --version`.

### 3. Code Editor
We recommend **Visual Studio Code** (VS Code) with the "Flutter" and "Rust" extensions installed.

### 4. Xcode (for iOS)
- Install **Xcode** from the Mac App Store to run the app on an iPhone simulator.

---

## 1. Project Setup
Open your terminal and navigate to the project folder:

```bash
cd /path/to/bonsaiflutter
```

### Install Dependencies
Run the following commands to install the necessary libraries for Flutter and Rust:

```bash
# Install Flutter packages
flutter pub get

# Install Cargo tools (needed for the bridge)
cargo install cargo-expand
cargo install flutter_rust_bridge_codegen
```

---

## 2. Generating the Bridge
This project uses `flutter_rust_bridge` to connect the Rust backend with the Flutter UI. You need to generate the code bindings once before running the app.

Run this command:
```bash
flutter_rust_bridge_codegen generate --rust-root rust --rust-input crate::api --dart-output lib/src/rust
```
*Note: This may take a minute.*

---

## 3. Running the App

### iOS Simulator
1. Open the Simulator app (or run `open -a Simulator`).
2. Run the app:
   ```bash
   flutter run
   ```
3. If prompted, select your simulator from the list.

### Troubleshooting
- **Build Errors**: If you see errors related to Pods, run:
  ```bash
  cd ios
  rm -rf Pods
  rm Podfile.lock
  pod install
  cd ..
  flutter run
  ```
- **Rust Errors**: Ensure generating the bridge (Step 2) completed successfully.

---

## 4. Helpful Commands

- **Hot Reload**: Press `r` in the terminal while the app is running to see changes instantly.
- **Full Restart**: Press `R` to fully restart the app.
- **Quit**: Press `q` to stop the app.

Enjoy building with **Bonsai**! 🌳
