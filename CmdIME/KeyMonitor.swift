import Carbon.HIToolbox
import CoreGraphics
import Foundation

/// 左⌘の単独タップで英数、右⌘の単独タップでかなキーを送出する。
enum KeyMonitor {
    nonisolated(unsafe) private static var tap: CFMachPort?
    nonisolated(unsafe) private static var pendingKey: Int64?

    /// キー入力とマウス入力を監視するイベントタップを作成し、メインランループで監視を開始する。
    ///
    /// アクセシビリティ権限がまだなくてイベントタップを作成できない場合は、
    /// 1 秒後に再試行する。権限が付与されるまで再試行を続ける。
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
            // アクセシビリティ権限が付与されるまで再試行する
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { start() }
            return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    }

    /// イベントタップで受け取ったイベントを処理し、⌘キーの単独タップを判定する。
    ///
    /// ⌘キーが押されたら、そのキーコードを記録する。記録したのと同じ⌘キーが、
    /// 途中で他のキーやマウスを操作されずに離されたら単独タップとみなし、
    /// 左⌘なら英数キー、右⌘ならかなキーを送出する。
    /// イベントタップが OS によって無効化された場合は、再び有効にする。
    ///
    /// - Parameters:
    ///   - type: 受け取ったイベントの種類。
    ///   - event: 受け取ったイベント。
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

    /// 指定したキーを 1 回押して離すキーイベントを送出する。
    ///
    /// 送出したキーイベントを macOS と IME が受け取り、入力モードを切り替える。
    ///
    /// - Parameter key: 送出するキーの仮想キーコード（`kVK_JIS_Eisu` または `kVK_JIS_Kana`）。
    private static func post(_ key: Int) {
        let source = CGEventSource(stateID: .hidSystemState)
        for down in [true, false] {
            CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(key), keyDown: down)?.post(tap: .cghidEventTap)
        }
    }
}
