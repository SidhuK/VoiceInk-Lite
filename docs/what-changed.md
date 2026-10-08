# What's different from VoiceInk

This is the full list. The [README](../README.md) has the short version.

VoiceInk Lite started from VoiceInk 2.21 (commit `c09cc1f`, October 2026). Everything below compares against that.

## By the numbers

The strip-down commit removed 37,242 lines and added 2,397, across 173 files. 52 files were deleted, 6 were new, and 115 were edited.

| What | Lines removed |
| --- | --- |
| Translations (German, French, Simplified Chinese) | 30,468 |
| Swift code | 5,329 |
| Release scripts, DMG files, release notes, GitHub templates, tests | about 1,450 |

Translations make up most of it. On the code side, the app went from 72,245 lines of Swift to 68,830. That's about 5% smaller. Most of what's left is the part that does the work, and that part is untouched.

## How I decided what to cut

I asked three questions about each piece.

1. Does it talk to a server run by the original developer? License checks, the update feed, announcements, and the GitHub star prompt all did. They're gone.
2. Does it only work when Prakash's own Apple developer account signs the app? iCloud sync and the shared keychain did. They're gone, or swapped for something that works on any Mac.
3. Is it only there to ship releases or run a public project? Release scripts, DMG artwork, notarization, release notes, translations, tests, and GitHub templates were. They're gone too.

Anything that didn't fit one of those stayed.

## Kept

- Recording, with the mini and notch recorder styles.
- Every transcription engine. That means Whisper, Parakeet, Apple's on-device speech, the local GGUF models, and the cloud providers.
- AI enhancement, with cloud providers, Ollama, local command-line tools, and on-device MLX models.
- Modes, including switching by app, website, or trigger word.
- The dictionary, word replacements, and Auto Learn.
- The AI assistant mode.
- Screen context, for better accuracy.
- History, audio file import, and the dashboard.
- Settings backup and restore.

## Removed

**Licensing.** No trial, license key, Polar license check, Pro badge, or license page. Without a license or an active trial, VoiceInk put a "Your trial has ended" message in front of everything it pasted. That's gone.

**Updates.** Sparkle, the update feed, and every Check for Updates button. To update, pull the repo and rebuild.

**Announcements and What's New.** No remote announcement feed and no release video popup.

**GitHub star prompt.** The dashboard no longer asks you to star the repo.

**Support links.** The support email form, the Copy System Info button, "contact support" text in error messages, and "Learn more" links to tryvoiceink.com.

**iCloud.** The dictionary no longer syncs through iCloud, and API keys no longer sync through iCloud Keychain. Both need the original developer's Apple account.

**Translations.** German, French, and Simplified Chinese, plus the language picker. The app is English only.

**Upgrade code.** Code that moved data forward from older VoiceInk versions. Lite starts with its own empty data folder, so there's nothing to upgrade.

**Project extras.** Tests, release and notarization scripts, DMG artwork, release notes, the separate "VoiceInk Dev" app, contributor docs, and GitHub templates.

## Changed

**Its own name and data.** The app is called VoiceInk Lite, with the bundle ID `com.karat.VoiceInkLite`. It keeps its settings, history, and most models in its own folder, so it runs next to the official VoiceInk without either one touching the other's data. Parakeet models are the one exception. [Where your data lives](reference/where-your-data-lives.md) has the details.

**API keys in the login keychain.** VoiceInk used a keychain type that needs a provisioning profile, which home builds don't have. Keys now go in your normal login keychain and stay on your Mac.

**Builds without a paid Apple account.** The app no longer asks for iCloud or shared keychain permissions. It also lets the app load its bundled frameworks when it's signed with a free certificate or none at all.

**One build type.** `make local`, Xcode Run, and Xcode Archive all make the same Release build. There's no separate debug app with its own name and data.

**Neutral examples.** Placeholder text in the dictionary screens uses generic words and `me@example.com` in place of the original developer's name and email.

## Added

**A smaller mini recorder.** The mini recorder is now a slim pill with ✕ to cancel, a moving waveform, and ✓ to finish. Right-click it to change mode. See [The recorder](using/recorder.md).

**Change modes by hovering.** Hover over the mini recorder and your modes show up as buttons. Click one to switch, even mid-recording.

**Live text only on hover.** Live text stays hidden while you talk, so it doesn't pull your eyes away. Hover over the recorder to see it. You can turn this off in Settings.

**More shortcut options.** A Hyper key shows up as "Hyper". The key left of 1 (` or §) works on its own. Using Fn alone gets a reminder about the macOS emoji picker setting, with a button to fix it. Arrow-key shortcuts no longer show a stray "Fn". See [Shortcuts](using/shortcuts.md).

**A usage dashboard.** The dashboard opens with cards built from your own history.

- Words per minute, with a gauge comparing your speaking speed to typing at 40 WPM.
- Fixes made, meaning words your AI prompts corrected plus dictionary replacements. Assistant replies don't count.
- Total words dictated, with progress toward a 90,000-word novel and a bar showing which modes you use most.
- App usage, meaning which kinds of apps you dictate into, such as AI chats, email, documents, and messages. App names never leave your Mac.
- A streak calendar showing the days you dictated, with your current and longest streak.

Fix counts and app usage start from your first dictation on this build. Older history doesn't have that data.
