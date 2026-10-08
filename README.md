# VoiceInk Lite

My personal build of [VoiceInk](https://github.com/Beingpax/VoiceInk), the macOS dictation app by Prakash Joshi. You hold a shortcut, talk, and the text lands wherever your cursor is. Transcription can run fully on your Mac.

I wanted the app without the parts that exist to sell, update, and support it as a commercial product. So I stripped those out, gave it its own identity so it can sit next to the official app, made it build with one command, and added a usage dashboard I like.

VoiceInk is GPL v3 and so is this. If VoiceInk is useful to you, buy a license from the original developer. This repo exists because the source is open, and he did the hard part.

## How I decided what to cut

I went through the codebase with three questions:

1. Does it call a server that belongs to the original developer? License checks, the update feed, announcements, and the GitHub star prompt all did. They went.
2. Does it only work when the app is signed by the original developer's Apple team? iCloud sync and the shared keychain group did. They went, or got replaced with something that works on any Mac.
3. Does it only matter for shipping releases or running a public project? Release scripts, DMG artwork, notarization, release notes, translations, test targets, and the GitHub templates. They went too.

Everything that does the actual work stayed: recording, every transcription engine, AI enhancement, Modes, the dictionary and Auto Learn, history, audio file import, and backups.

## What's different from VoiceInk

### Removed

- **Licensing.** No trial, license key, Polar validation, Pro badge, or license page. The unlicensed build also stuck a reminder message in front of your pasted text. That's gone.
- **Updates.** Sparkle, the appcast, and every "Check for Updates" button. You update by pulling and rebuilding.
- **Announcements and What's New.** No remote announcement feed and no release video popup.
- **GitHub star prompt.** The dashboard no longer asks you to star the repo through the `gh` CLI.
- **Support plumbing.** The support email form, the "Copy System Info" footer button, "contact support" error text, and the "Learn more" links to tryvoiceink.com.
- **iCloud.** The dictionary no longer syncs through CloudKit, and API keys no longer sync through iCloud Keychain. Both need the original developer's Apple team.
- **Translations.** German, French, and Simplified Chinese strings and the in-app language picker. The app is English only.
- **Upgrade migrations.** Code that moved data forward from older VoiceInk versions. Lite starts with a clean data folder, so there's nothing to migrate.
- **Project overhead.** Test targets, release and notarization scripts, DMG assets, release notes, the separate "VoiceInk Dev" build, and the contributor docs and GitHub templates.

### Changed

- **Its own identity.** The app is called VoiceInk Lite with bundle ID `com.karat.VoiceInkLite`. Settings, history, and most models live in their own folder, so it runs next to the official VoiceInk without either app touching the other's data. Parakeet models are the one exception. FluidAudio keeps them in a shared folder, so both apps reuse the same download.
- **API keys in the login keychain.** Upstream used the Data Protection keychain, which needs a provisioning profile that local builds don't have. Keys now go in your normal login keychain and stay on this Mac.
- **Signing that works without a paid account.** Entitlements no longer ask for iCloud or keychain groups. Library validation is off so the app can load its bundled frameworks with a personal or ad-hoc signature.
- **One build configuration.** `make local`, Xcode Run, and Xcode Archive all build Release. There's no separate debug app with a different name and data folder.
- **Neutral placeholders.** Example text in the dictionary screens uses generic words and `me@example.com` in place of the original developer's name and email.

### Added: usage dashboard

The dashboard now opens with a set of cards built from your own dictation history:

- **Words per minute.** Your average speaking speed, with a gauge comparing it to typing at 40 WPM.
- **Fixes made by VoiceInk.** Words your AI prompts corrected, plus how often a dictionary replacement rule fixed a word. Assistant-style replies don't count as corrections.
- **Total words dictated.** With progress toward a 90,000-word novel and a bar showing which Modes you use most.
- **App usage.** Which kinds of apps you dictate into: AI prompts, email, documents, work messages, personal messages, and everything else. App names stay on your Mac.
- **Streak.** A calendar heatmap of the days you dictated, with your current and longest streak.

Fix counts and app usage start from the first dictation you make on this build. Older history doesn't have that data.

## Requirements

- A Mac with Apple Silicon. The build is arm64 only, and the on-device MLX models need Apple Silicon anyway.
- macOS 15 or later to run the app.
- Xcode 26 or later to build it. I build with Xcode 27.
- About 8 GB of free disk space on top of Xcode. On my Mac the build folder is 4.6 GB and whisper.cpp is 1.5 GB, plus the Metal toolchain. Models you download later need more.

## Set up a fresh Mac

Do this once. After that, skip to [Clone and build](#clone-and-build-it-yourself).

1. **Install Xcode** from the App Store. Open it once, accept the license, and let it finish installing components.

2. **Point the command line at Xcode** and make sure the Command Line Tools are present:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app
   xcode-select --install
   ```

   If `xcode-select --install` says the tools are already installed, that's fine.

3. **Install the Metal toolchain.** Newer Xcode versions download it separately, and the MLX package won't compile without it:

   ```bash
   xcodebuild -downloadComponent MetalToolchain
   ```

4. **Install Homebrew and CMake.** whisper.cpp needs CMake to build:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew install cmake
   ```

   Follow the "Next steps" Homebrew prints at the end so `brew` is on your PATH.

5. **Optional: get a free signing certificate.** Without one, macOS treats every rebuild as a new app and asks for microphone and accessibility permission again. To avoid that, open Xcode > Settings > Accounts, sign in with your Apple ID, select your team, click Manage Certificates, and add an Apple Development certificate. A free Apple ID is enough.

Check that everything is there:

```bash
xcodebuild -version
cmake --version
git --version
```

## Clone and build it yourself

```bash
git clone https://github.com/SidhuK/VoiceInk-Lite.git
cd VoiceInk-Lite
make local
```

The first `make local` takes a while. It clones whisper.cpp into `~/VoiceInk-Dependencies` and builds `whisper.xcframework`, resolves the Swift packages, and builds the app in Release. Later builds reuse all of that and are much faster.

When it finishes, the app is at `~/Downloads/VoiceInk Lite.app`. Move it to Applications and open it:

```bash
mv ~/Downloads/"VoiceInk Lite.app" /Applications/
open "/Applications/VoiceInk Lite.app"
```

Onboarding walks you through permissions and picking a model:

- **Microphone** to record.
- **Accessibility** to paste text into other apps.
- **Screen Recording** is optional. It lets the app read on-screen context to improve accuracy.

`make dev` builds, installs to Downloads, and launches the app in one step. That's handy while you're changing code.

### Signing

If your keychain has exactly one Apple Development certificate, the build uses it. Otherwise it signs ad-hoc and prints a warning. To pick a certificate or force ad-hoc:

```bash
security find-identity -v -p codesigning     # list your certificates
make local CODESIGN_IDENTITY="<SHA or name>"
make local CODESIGN_IDENTITY=-               # ad-hoc
```

### Updating

```bash
cd VoiceInk-Lite
git pull
make local
```

Then replace the copy in Applications with the new one from Downloads. If you sign with the same certificate each time, your permissions carry over.

### Building in Xcode

```bash
make setup
open VoiceInk.xcodeproj
```

Pick the `VoiceInk` scheme and press Run. To keep permissions across rebuilds, set your team under Signing & Capabilities.

See [BUILDING.md](BUILDING.md) for every `make` target.

## Build it for someone else

The other person doesn't need Xcode. You build the app, zip it, and send it over. They need an Apple Silicon Mac on macOS 15 or later.

1. Build on your Mac:

   ```bash
   make local
   ```

2. Zip it. Finder's Compress works, or use `ditto`, which keeps the code signature intact:

   ```bash
   ditto -c -k --keepParent ~/Downloads/"VoiceInk Lite.app" ~/Desktop/VoiceInk-Lite.zip
   ```

3. Send `VoiceInk-Lite.zip` by AirDrop, a shared drive, or whatever you like.

The app isn't notarized, because that takes a paid Apple Developer account. The first time they open it, macOS will block it. Here's what they do:

1. Unzip it and drag **VoiceInk Lite** to Applications.
2. Double-click it. macOS says it can't verify the app. Click **Done**.
3. Open **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to the VoiceInk Lite message. Confirm with their password.
4. Go through onboarding and grant Microphone and Accessibility.

If they're comfortable with Terminal, this does the same as steps 2 and 3:

```bash
xattr -dr com.apple.quarantine "/Applications/VoiceInk Lite.app"
```

A few things to know:

- **Sign it with your certificate** if you plan to send updates. Their permissions carry over when the signature stays the same. Ad-hoc builds make them re-approve after every update.
- **Their data is theirs.** API keys go into their own keychain, and history stays on their Mac. Nothing from your copy goes with the app.
- **Point them at this repo.** The GPL says that if you give someone the app, they get access to the source too. A link to this repository covers that.

## Where your data lives

| What | Where |
| --- | --- |
| History, dictionary, stats, custom sounds, Whisper and other local models | `~/Library/Application Support/com.karat.VoiceInkLite/` |
| Parakeet models (shared with VoiceInk) | `~/Library/Application Support/FluidAudio/Models/` |
| Settings | `~/Library/Preferences/com.karat.VoiceInkLite.plist` |
| API keys | Login keychain |
| Build dependencies | `~/VoiceInk-Dependencies/` |
| Build output | `.local-build/` in the repo |

To move settings over from the official VoiceInk, use Settings > Backup > Export there, then Settings > Backup > Import in VoiceInk Lite.

## Troubleshooting

**macOS keeps asking for permissions after each rebuild.** The app is ad-hoc signed. Set up a free Apple Development certificate (step 5 of the fresh Mac setup) and rebuild. If permissions still look stuck, remove VoiceInk Lite from the Microphone and Accessibility lists in System Settings, then add it again.

**The build fails with a missing Metal toolchain.** Run `xcodebuild -downloadComponent MetalToolchain` and build again.

**The whisper step fails.** Check `cmake --version`. whisper.cpp's script builds for every Apple platform, so if it fails on an iOS, tvOS, or visionOS step, install those platforms in Xcode > Settings > Components. To start the whisper build over, delete `~/VoiceInk-Dependencies` and run `make local` again.

**Swift packages won't resolve.** Run `make clean`, then `make local`. That throws away `.local-build`, including the package cache.

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).

VoiceInk Lite is a modified version of [VoiceInk](https://github.com/Beingpax/VoiceInk) by Prakash Joshi.

## Acknowledgments

### Core technology

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - High-performance inference of OpenAI's Whisper model
- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Used for Parakeet model implementation
- [TranscribeCpp for Swift](https://github.com/Beingpax/Transcribe-cpp-swift) - SwiftPM distribution of [transcribe.cpp](https://github.com/handy-computer/transcribe.cpp), used for local GGUF transcription models
- [SenseVoice Small](https://huggingface.co/FunAudioLLM/SenseVoiceSmall) by FunAudioLLM / Alibaba - Multilingual model available under the [FunASR Model Open Source License Agreement](https://github.com/modelscope/FunASR/blob/main/MODEL_LICENSE)

### Dependencies

- [LLMkit](https://github.com/Beingpax/LLMkit) - AI provider clients for enhancement
- [MLX Swift LM](https://github.com/ml-explore/mlx-swift-lm), [swift-transformers](https://github.com/huggingface/swift-transformers), [swift-huggingface](https://github.com/huggingface/swift-huggingface) - On-device language models
- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) - Markdown rendering
- [MediaRemoteAdapter](https://github.com/Beingpax/mediaremote-adapter) - Media playback control during recording
- [SelectedTextKit](https://github.com/Beingpax/SelectedTextKit) - Reading selected text
- [Zip](https://github.com/marmelroy/Zip) - Backup compression
- [Swift Atomics](https://github.com/apple/swift-atomics) - Atomic operations
