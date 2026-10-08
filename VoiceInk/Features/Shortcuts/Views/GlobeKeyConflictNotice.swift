import AppKit
import SwiftUI

/// Reads the system "Press 🌐 key to" setting. macOS handles the Globe/Fn key itself, so a
/// shortcut that uses Fn on its own also opens the emoji picker or switches input source unless
/// the system action is set to "Do Nothing".
enum GlobeKeySystemAction {
    private static let domain = "com.apple.HIToolbox" as CFString
    private static let key = "AppleFnUsageType" as CFString
    private static let doNothingValue = 0

    static var isDoNothing: Bool {
        // Picks up changes made in System Settings since the value was last read.
        CFPreferencesAppSynchronize(domain)

        guard
            let value = CFPreferencesCopyValue(key, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
                as? Int
        else {
            // A missing value means the system default, which is never "Do Nothing".
            return false
        }

        return value == doNothingValue
    }

    static func conflicts(withShortcutsFor actions: [ShortcutAction]) -> Bool {
        let usesFunctionKey = actions.contains {
            ShortcutStore.shortcut(for: $0)?.isFunctionModifierShortcut == true
        }
        return usesFunctionKey && !isDoNothing
    }

    static func openKeyboardSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

struct GlobeKeyConflictNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "globe")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("macOS also reacts to the 🌐 Fn key")
                    .font(.system(size: 12, weight: .semibold))
                Text(
                    "To stop it opening the emoji picker or switching input source, set \"Press 🌐 key to\" to \"Do Nothing\" in Keyboard settings."
                )
                .settingsDescription()

                Button("Open Keyboard Settings") {
                    GlobeKeySystemAction.openKeyboardSettings()
                }
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }
}
