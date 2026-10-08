# Where your data lives

VoiceInk Lite keeps its data apart from the official VoiceInk, so you can run both on one Mac.

| What | Where |
| --- | --- |
| History, dictionary, stats, custom sounds, Whisper and other local models | `~/Library/Application Support/com.karat.VoiceInkLite/` |
| Parakeet models, shared with VoiceInk | `~/Library/Application Support/FluidAudio/Models/` |
| Settings | `~/Library/Preferences/com.karat.VoiceInkLite.plist` |
| API keys | Your login keychain |
| Build dependencies | `~/VoiceInk-Dependencies/` |
| Build output | `.local-build/` inside the repo |

Parakeet models are the one thing both apps share. The FluidAudio library always stores them in the same folder, so a model you downloaded in one app works in the other without a second download.

## Moving over from VoiceInk

1. In VoiceInk, go to Settings, then Backup, and click Export.
2. In VoiceInk Lite, go to Settings, then Backup, and click Import.

API keys don't come across in a backup. Add them again in VoiceInk Lite.
