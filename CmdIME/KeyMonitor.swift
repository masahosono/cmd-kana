import Carbon.HIToolbox
import CoreGraphics
import Foundation

/// Sends the Eisu key when the left Command key is tapped alone, and the Kana key when the right one is.
enum KeyMonitor {
    /// The event tap that monitors input, or `nil` until it is created.
    ///
    /// Kept so the tap can be re-enabled when the system disables it.
    nonisolated(unsafe) private static var tap: CFMachPort?

    /// The key code of the Command key that is currently held and still counts as a solo tap.
    ///
    /// Set when a Command key is pressed. Reset to `nil` when that key is released,
    /// or when any other key, modifier, or mouse button is pressed first.
    nonisolated(unsafe) private static var pendingKey: Int64?

    /// Creates an event tap for key and mouse input and starts monitoring on the main run loop.
    ///
    /// If the event tap cannot be created because Accessibility permission has not been granted yet,
    /// retries after one second, and keeps retrying until the permission is granted.
    static func start() {
        let types: [CGEventType] = [.flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | 1 << $1.rawValue }
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, _ in
                KeyMonitor.handle(type, event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil)
        guard let tap else {
            // Retry until Accessibility permission is granted.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { start() }
            return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    }

    /// Handles an event received by the event tap and detects a solo tap of a Command key.
    ///
    /// Records the key code when a Command key is pressed. If the same Command key is released
    /// with no other key or mouse input in between, the press counts as a solo tap, and this sends
    /// the Eisu key for the left Command key or the Kana key for the right one.
    /// Re-enables the event tap if the system has disabled it.
    ///
    /// - Parameters:
    ///   - type: The event type, such as `flagsChanged` for modifier keys, `keyDown`,
    ///     a mouse-down type, or `tapDisabledByTimeout` when the system has disabled the tap.
    ///   - event: The event whose key code and modifier flags identify
    ///     which Command key was pressed or released.
    private static func handle(_ type: CGEventType, _ event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            // NX_DEVICELCMDKEYMASK / NX_DEVICERCMDKEYMASK
            let deviceMask: UInt64 = switch Int(keyCode) {
            case kVK_Command: 0x08
            case kVK_RightCommand: 0x10
            default: 0
            }
            if deviceMask != 0, event.flags.rawValue & deviceMask != 0 {
                pendingKey = keyCode
            } else {
                if deviceMask != 0, pendingKey == keyCode {
                    post(keyCode == kVK_Command ? kVK_JIS_Eisu : kVK_JIS_Kana)
                }
                pendingKey = nil
            }
        default:
            pendingKey = nil
        }
    }

    /// Posts key events that press and release the given key once.
    ///
    /// macOS and the input method receive these events and switch the input mode.
    ///
    /// - Parameter key: The virtual key code to post (`kVK_JIS_Eisu` or `kVK_JIS_Kana`).
    private static func post(_ key: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: down)?.post(tap: .cghidEventTap)
        }
    }
}
