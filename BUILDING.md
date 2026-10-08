# Building VoiceInk Lite

## Requirements

- Apple Silicon Mac, macOS 15.0 or later
- Xcode 26 or later, with Command Line Tools
- Metal toolchain: `xcodebuild -downloadComponent MetalToolchain`
- CMake, for whisper.cpp: `brew install cmake`
- Git

For a step-by-step setup on a new Mac, see the [README](README.md#set-up-a-fresh-mac).

## Build and Install

From the project folder:

```bash
make local
open ~/Downloads/"VoiceInk Lite.app"
```

`make local` builds `whisper.xcframework` in `~/VoiceInk-Dependencies` on first run, builds Release into `.local-build`, and copies `VoiceInk Lite.app` to `~/Downloads`. `make dev` does the same and then launches the app.

## Signing

If exactly one Apple Development identity is in your keychain, the build uses it. Otherwise it signs ad-hoc. With ad-hoc signing, macOS may ask for microphone and accessibility permissions again after each rebuild.

Pick an identity, or force ad-hoc:

```bash
make local CODESIGN_IDENTITY="<SHA or name>"
make local CODESIGN_IDENTITY=-
```

## Other Commands

- `make build` - build Release into `.local-build` without copying
- `make run` - launch the installed app, or the one in `.local-build`
- `make whisper` - prepare `whisper.xcframework`
- `make check` - verify required tools
- `make clean` - remove `.local-build`
- `make help` - list commands

## Build with Xcode

```bash
make setup
open VoiceInk.xcodeproj
```

Select the `VoiceInk` scheme. Run and Archive both use the Release configuration. To keep permissions across rebuilds, set your own team under Signing & Capabilities.
