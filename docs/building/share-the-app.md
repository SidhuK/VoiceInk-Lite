# Share the app with someone

The other person doesn't need Xcode. You build the app, zip it, and send it. They need an Apple Silicon Mac on macOS 15 or later.

## On your Mac

1. Build it.

   ```bash
   make local
   ```

2. Zip it. Finder's Compress works. So does `ditto`, which keeps the code signature intact.

   ```bash
   ditto -c -k --keepParent ~/Downloads/"VoiceInk Lite.app" ~/Desktop/VoiceInk-Lite.zip
   ```

3. Send `VoiceInk-Lite.zip` by AirDrop, a shared drive, or however you like.

## On their Mac

The app isn't notarized, because notarizing needs a paid Apple Developer account. macOS blocks it the first time it opens.

1. Unzip it and drag VoiceInk Lite to Applications.
2. Double-click it. macOS says it can't verify the app. Click Done.
3. Open System Settings, then Privacy & Security. Scroll down and click Open Anyway next to the VoiceInk Lite message. Confirm with the account password.
4. Go through the first-launch setup and allow Microphone and Accessibility.

If they're comfortable with Terminal, this one command replaces steps 2 and 3:

```bash
xattr -dr com.apple.quarantine "/Applications/VoiceInk Lite.app"
```

## Good to know

- Sign with your own certificate if you plan to send updates. Their permissions carry over as long as the signature stays the same. With ad-hoc builds they have to approve permissions again after every update.
- Their data stays theirs. API keys go into their own keychain and history stays on their Mac. Nothing from your copy travels with the app.
- Send them a link to this repo too. The GPL says anyone you give the app to should be able to get the source, and a link covers that.
