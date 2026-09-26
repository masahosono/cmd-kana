import ApplicationServices
import ServiceManagement
import SwiftUI

@main
struct CmdIMEApp: App {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// アクセシビリティ権限を確認してから、キー入力の監視を開始する。
    ///
    /// 権限がない場合は、許可を求めるシステムのダイアログを表示する。
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
