# Build and install

This page assumes your Mac already has Xcode, the Metal toolchain, and CMake. If it doesn't, start with [Set up a new Mac](new-mac-setup.md).

## Build it

```bash
git clone https://github.com/SidhuK/VoiceInk-Lite.git
cd VoiceInk-Lite
make local
```

The first build takes a while. It downloads whisper.cpp into `~/VoiceInk-Dependencies`, builds it, fetches the Swift packages, and then builds the app. Later builds reuse all of that and finish much faster.

When it's done, the app is at `~/Downloads/VoiceInk Lite.app`. Move it to Applications and open it:

```bash
mv ~/Downloads/"VoiceInk Lite.app" /Applications/
open "/Applications/VoiceInk Lite.app"
```

The first launch walks you through permissions and picking a model.

- Microphone is needed to record.
- Accessibility is needed to paste text into other apps.
- Screen Recording is optional. It lets the app read what's on screen to improve accuracy.

If you also have the official VoiceInk or an older copy of Lite running, quit it first. Two copies will fight over the same shortcuts.

## Update it

```bash
cd VoiceInk-Lite
git pull
make local
```

Then replace the copy in Applications with the new one from Downloads. If you sign with the same certificate each time, macOS keeps your permissions.

## Signing

If your keychain has exactly one Apple Development certificate, the build uses it. Otherwise it signs ad-hoc and prints a warning. Ad-hoc builds work, but macOS treats each rebuild as a new app and asks for microphone and accessibility permission again.

To pick a certificate, or to force ad-hoc signing:

```bash
security find-identity -v -p codesigning     # list your certificates
make local CODESIGN_IDENTITY="<SHA or name>"
make local CODESIGN_IDENTITY=-               # ad-hoc
```

A free Apple ID is enough to get a certificate. [Set up a new Mac](new-mac-setup.md#optional-get-a-free-signing-certificate) shows how.

## All `make` commands

| Command | What it does |
| --- | --- |
| `make local` | Builds the app and copies it to `~/Downloads`. This is the default. |
| `make dev` | Same as `make local`, then opens the app. Handy while changing code. |
| `make build` | Builds into `.local-build` without copying it anywhere. |
| `make run` | Opens the copy in Downloads, or the one in `.local-build`. |
| `make whisper` | Downloads and builds whisper.cpp only. |
| `make setup` | Checks your tools and builds whisper.cpp. Run this before opening the project in Xcode. |
| `make check` | Checks that git, Xcode, and Swift are installed. |
| `make clean` | Deletes `.local-build`, including the package cache. |
| `make help` | Lists these commands. |

## Build in Xcode

```bash
make setup
open VoiceInk.xcodeproj
```

Pick the `VoiceInk` scheme and press Run. Run and Archive both use the Release configuration, so there's no separate debug app. To keep permissions across rebuilds, set your team under Signing & Capabilities.
