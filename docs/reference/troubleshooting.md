# Troubleshooting

## macOS keeps asking for permissions after each rebuild

The app is signed ad-hoc, so macOS sees every build as a new app. Get a free Apple Development certificate ([how](../building/new-mac-setup.md#optional-get-a-free-signing-certificate)) and rebuild.

If permissions still look stuck, remove VoiceInk Lite from the Microphone and Accessibility lists in System Settings, then add it again.

## Pressing Fn opens the emoji picker

macOS has its own action for the 🌐 Fn key. Open System Settings, then Keyboard, and set "Press 🌐 key to" to "Do Nothing". [Shortcuts](../using/shortcuts.md#using-the-fn-key) has more detail.

## A shortcut does nothing

- Check that VoiceInk Lite has Accessibility permission. Global shortcuts need it.
- Quit the official VoiceInk or any other copy of Lite. Two apps listening for the same shortcut get in each other's way.
- If you use Karabiner or a Hyper key app, check that it's running.

## The build fails with a missing Metal toolchain

```bash
xcodebuild -downloadComponent MetalToolchain
```

Then build again.

## The whisper step fails

Check that `cmake --version` works. whisper.cpp builds for every Apple platform, so if it fails on an iOS, tvOS, or visionOS step, install those platforms in Xcode under Settings, then Components.

To start the whisper build over, delete `~/VoiceInk-Dependencies` and run `make local` again.

## Swift packages won't resolve

```bash
make clean
make local
```

`make clean` throws away `.local-build`, including the package cache.
