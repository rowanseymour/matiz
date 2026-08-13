import AppKit
import SwiftUI

@main
struct MatizApp: App {
    init() {
        // Needed when launched via `swift run` (no app bundle): become a regular
        // foreground app with a Dock icon and key window.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup("Matiz") {
            ContentView()
                .frame(minWidth: 560, minHeight: 480)
        }

        Settings {
            SettingsView()
        }
    }
}
