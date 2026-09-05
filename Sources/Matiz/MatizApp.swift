import AppKit
import SwiftUI

@main
struct MatizApp: App {
    init() {
        // Needed when launched via `swift run` (no app bundle): become a regular
        // foreground app with a Dock icon and key window, and set the Dock icon by
        // hand since there's no Info.plist to point at the .icns. A real bundle
        // (bin/install) gets all of this from its Info.plist, and Bundle.module
        // doesn't resolve from inside one.
        guard !Bundle.main.bundlePath.hasSuffix(".app") else { return }
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
        }
        // The window can't shrink below its content, and the content's only fixed
        // width is the language bar, so that bar sets the minimum width. The default
        // size is deliberately smaller than that minimum so a new window opens at
        // exactly the bar's width rather than some guessed number.
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 420)

        Settings {
            SettingsView()
        }
    }
}
