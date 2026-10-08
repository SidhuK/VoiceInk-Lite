# Set up a new Mac

You only do this once per Mac. After that, follow [Build and install](build-and-install.md).

## What you need

- A Mac with Apple Silicon. The build is arm64 only, and the on-device MLX models need Apple Silicon anyway.
- macOS 15 or later to run the app.
- Xcode 26 or later to build it.
- About 8 GB of free disk space on top of Xcode. The build folder is around 4.6 GB and whisper.cpp around 1.5 GB. Models you download later take more.

## 1. Install Xcode

Get Xcode from the App Store. Open it once, accept the license, and let it finish installing its components.

## 2. Point the command line at Xcode

```bash
sudo xcode-select -s /Applications/Xcode.app
xcode-select --install
```

If the second command says the tools are already installed, that's fine.

## 3. Install the Metal toolchain

Newer versions of Xcode download it separately, and the on-device AI package won't compile without it.

```bash
xcodebuild -downloadComponent MetalToolchain
```

## 4. Install Homebrew and CMake

whisper.cpp needs CMake to build.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install cmake
```

Follow the "Next steps" Homebrew prints at the end so `brew` works in new Terminal windows.

## Optional: get a free signing certificate

Without one, macOS asks for microphone and accessibility permission again after every rebuild. To fix that:

1. Open Xcode, then Settings, then Accounts.
2. Sign in with your Apple ID and select your team.
3. Click Manage Certificates and add an Apple Development certificate.

A free Apple ID works. You don't need a paid developer account.

## Check that it worked

```bash
xcodebuild -version
cmake --version
git --version
```

If all three print a version, you're ready for [Build and install](build-and-install.md).
