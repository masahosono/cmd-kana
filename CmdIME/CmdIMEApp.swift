import ApplicationServices
import ServiceManagement
import SwiftUI

@main
struct CmdIMEApp: App {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// Checks for Accessibility permission, then starts monitoring key input.
    ///
    /// If the permission has not been granted, shows the system dialog that asks for it.
    init() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        KeyMonitor.start()
    }

    var body: some Scene {
        MenuBarExtra("CmdIME", systemImage: "command") {
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
