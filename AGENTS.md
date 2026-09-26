# AGENTS.md

CmdIME is a macOS menu bar app: tapping the left ⌘ key alone switches to Eisu (English) input, and the right ⌘ key to Kana (Japanese) input. It replaces the unmaintained [cmd-eikana](https://github.com/iMasanari/cmd-eikana).

## Principles

- Keep the feature set and the code minimal. Do not add features, settings, or dependencies unless asked.
- Use current Apple APIs. Check the SDK (`xcrun --sdk macosx --show-sdk-path`) for availability and deprecations rather than relying on memory.

## Structure

- `CmdIME/CmdIMEApp.swift`: app entry point and `MenuBarExtra` menu (launch at login, quit)
- `CmdIME/KeyMonitor.swift`: listen-only `CGEvent` tap that detects a solo ⌘ tap and posts `kVK_JIS_Eisu` / `kVK_JIS_Kana` key events
- `CmdIME.xcodeproj`: uses a folder-synchronized group, so new files under `CmdIME/` are picked up without editing `project.pbxproj`

Settings live in build settings (`GENERATE_INFOPLIST_FILE`, `INFOPLIST_KEY_LSUIElement`); there is no Info.plist file. App Sandbox is off because the event tap and event posting need it off.

## Build

```sh
xcodebuild -project CmdIME.xcodeproj -scheme CmdIME -configuration Release -derivedDataPath build CODE_SIGN_IDENTITY=- build
```

There are no automated tests. Key switching needs Accessibility permission and must be verified manually by the user.

## Conventions

- Swift 6 language mode; minimum deployment target macOS 15.
- Write code comments in English. Give every declaration a `///` doc comment (summary line, optional discussion, `- Parameter(s):`), except protocol requirements such as `body`.
- UI strings are Japanese.
- `README.md` (English) and `README_ja.md` (Japanese) must stay in sync; update both together.
