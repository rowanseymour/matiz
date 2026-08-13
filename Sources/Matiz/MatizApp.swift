import AppKit
import SwiftUI

@main
struct MatizApp: App {
    init() {
        // Needed when launched via `swift run` (no app bundle): become a regular
        // foreground app with a Dock icon and key window, and set the Dock icon by
        // hand since there's no Info.plist to point at the .icns.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let url = Bundle.module.url(forResource: "Matiz", withExtension: "icns") {
                NSApplication.shared.applicationIconImage = NSImage(contentsOf: url)
            }
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
