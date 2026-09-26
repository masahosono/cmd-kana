import ApplicationServices
import ServiceManagement
import SwiftUI

/// A menu bar app that switches between Eisu and Kana input with the left and right Command keys.
@main
struct CmdKanaApp: App {
    /// Whether the app is registered to launch at login, kept in sync with `SMAppService.mainApp`.
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// Checks for Accessibility permission, then starts monitoring key input.
    ///
    /// If the permission has not been granted, shows the system dialog that asks for it.
    init() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        KeyMonitor.start()
    }

    var body: some Scene {
        MenuBarExtra("CmdKana", systemImage: "command") {
            Toggle("ログイン時に起動", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            Divider()
            Button("終了") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
