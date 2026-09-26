import ApplicationServices
import ServiceManagement
import SwiftUI

/// A menu bar app that switches between Eisu and Kana input with the left and right Command keys.
@main
struct CmdKanaApp: App {
    /// Whether the app is registered to launch at login, kept in sync with `SMAppService.mainApp`.
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// Whether Accessibility permission was granted when this process launched.
    ///
    /// Fixed for the lifetime of the process, because the app relaunches itself once the permission is granted.
    private let isTrusted: Bool

    /// The menu bar icon: the kana "か" inside a rounded square, drawn as a template image
    /// so that it matches the menu bar appearance.
    private static let icon: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            let border = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
            border.lineWidth = 1.5
            NSColor.black.setStroke()
            border.stroke()
            let text = NSAttributedString(string: "か", attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold)])
            let size = text.size()
            text.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
            return true
        }
        image.isTemplate = true
        return image
    }()

    /// Starts monitoring key input if Accessibility permission has been granted.
    ///
    /// Otherwise, shows the system dialog that asks for the permission and waits for it.
    init() {
        isTrusted = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        if isTrusted {
            KeyMonitor.start()
        } else {
            Self.relaunchWhenTrusted()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            if !isTrusted {
                Button("アクセシビリティを許可…") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                Divider()
            }
            Toggle("ログイン時に起動", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            Divider()
            Button("終了") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            if isTrusted {
                Image(nsImage: Self.icon)
            } else {
                Image(systemName: "exclamationmark.triangle")
            }
        }
    }

    /// Checks for Accessibility permission every second and relaunches the app once it is granted.
    ///
    /// Relaunching makes sure the event tap is created by a process that has the permission.
    private static func relaunchWhenTrusted() {
        Task {
            while !AXIsProcessTrusted() {
                try? await Task.sleep(for: .seconds(1))
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            _ = try? await NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration)
            NSApplication.shared.terminate(nil)
        }
    }
}
