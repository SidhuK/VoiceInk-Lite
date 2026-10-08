# VoiceInk Lite

A trimmed-down build of [VoiceInk](https://github.com/Beingpax/VoiceInk), the Mac dictation app by Prakash Joshi. Hold a shortcut, talk, and your words show up wherever your cursor is. Transcription can run entirely on your Mac.

I liked VoiceInk but didn't need the parts that exist to sell and support it as a product. So I took those out, kept everything that does the actual work, and changed a few things to suit the way I use it.

If VoiceInk is useful to you, [buy a license](https://tryvoiceink.com) from the original developer. He did the hard part. This build only exists because he made the source open.

## What I kept

Everything that turns your voice into text.

- All the transcription engines, local and cloud.
- AI Enhancement, which cleans up your text using cloud providers, Ollama, or models that run on your Mac.
- Modes, which switch settings based on the app or website you're in.
- The dictionary, word replacements, and Auto Learn.
- The AI assistant, history, audio file import, and settings backup.

## What I cut

About 37,000 lines in total. Around 30,500 were translations and around 5,300 were Swift code for things a personal build doesn't need. The rest was release scripts and project files.

- Licensing, the free trial, and the "Your trial has ended" message added to your text.
- Automatic updates. You update by pulling the repo and rebuilding.
- Announcements, the What's New popup, and the prompt asking you to star the repo.
- Support forms and links back to the VoiceInk website.
- iCloud sync, which only works for apps signed by the original developer.
- Translations. The app is English only.
- Release scripts, tests, and other tools for running a public project.

## What I changed

- It has its own name and data folder, so it runs next to the official VoiceInk without touching its data.
- You can build it without a paid Apple developer account. A free Apple ID helps, but isn't required.
- The mini recorder is a slim pill with ✕ to cancel and ✓ to finish.
- Hover over the recorder to switch modes. No more digging through the menu bar.
- Live text stays hidden while you talk. Hover over the recorder to see it.
- Better shortcuts. The ` key next to 1 works on its own, Hyper keys show up as "Hyper", and the app tells you how to stop Fn from opening the emoji picker.
- The dashboard shows your speaking speed, words dictated, fixes made, the apps you dictate into, and your daily streak.

The full list, with numbers, is in [What's different from VoiceInk](docs/what-changed.md).

## Get it

You need a Mac with Apple Silicon running macOS 15 or later, and Xcode to build it.

```bash
git clone https://github.com/SidhuK/VoiceInk-Lite.git
cd VoiceInk-Lite
make local
```

The app ends up in your Downloads folder. Move it to Applications and open it.

First time building on this Mac? Start with [Set up a new Mac](docs/building/new-mac-setup.md). It covers Xcode, CMake, and a free signing certificate.

## Docs

| If you want to | Read |
| --- | --- |
| Set up a Mac to build the app | [Set up a new Mac](docs/building/new-mac-setup.md) |
| Build, update, or sign the app | [Build and install](docs/building/build-and-install.md) |
| Give the app to a friend | [Share the app](docs/building/share-the-app.md) |
| Learn the recorder and hover controls | [The recorder](docs/using/recorder.md) |
| Set up Fn, Hyper, or other shortcuts | [Shortcuts](docs/using/shortcuts.md) |
| Find your data or move from VoiceInk | [Where your data lives](docs/reference/where-your-data-lives.md) |
| Fix a problem | [Troubleshooting](docs/reference/troubleshooting.md) |
| See every change from VoiceInk | [What's different](docs/what-changed.md) |

## License

GNU General Public License v3.0, the same as VoiceInk. See [LICENSE](LICENSE).

VoiceInk Lite is a modified version of [VoiceInk](https://github.com/Beingpax/VoiceInk) by Prakash Joshi. It's built on whisper.cpp, FluidAudio, MLX, and other open-source projects listed in [Credits](docs/reference/credits.md).
