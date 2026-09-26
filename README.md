# CmdKana

English | [日本語](README_ja.md)

A macOS menu bar app that switches between Eisu (English) and Kana (Japanese) input with the left and right Command keys.
It replaces [⌘英かな (cmd-eikana)](https://github.com/iMasanari/cmd-eikana), which is no longer maintained, and implements only the essential features.

## Features

- Tap the left ⌘ key alone → Eisu (English input)
- Tap the right ⌘ key alone → Kana (Japanese input)
- Runs in the menu bar and does not appear in the Dock
- Launch at login (toggle from the menu)

The input mode does not switch if you press another key or use the mouse while holding ⌘, so shortcuts such as ⌘C are not affected.

## Requirements

- macOS 15 or later
- Xcode 16 or later (to build)

## Install from Releases

1. Download `CmdKana-vX.Y.Z.dmg` from [Releases](https://github.com/masahosono/cmd-kana/releases).
2. Open the DMG and drag `CmdKana.app` to `Applications`.
3. Launch `CmdKana.app`. The app is not notarized, so macOS blocks it the first time. Open System Settings > Privacy & Security, click Open Anyway for CmdKana, and launch it again.

The app is ad-hoc signed, so its signature changes with every release. After updating, remove CmdKana from the Accessibility list and allow it again.

## Build from source

1. Open `CmdKana.xcodeproj` in Xcode.
2. Select your Team under Signing & Capabilities for the CmdKana target.
   - Setting a Team is recommended because Accessibility permission is reset whenever the code signature changes.
3. Use Product > Archive, or build and copy the generated `CmdKana.app` to `/Applications`.
4. Launch `CmdKana.app`.

To build from the command line:

```sh
xcodebuild -project CmdKana.xcodeproj -scheme CmdKana -configuration Release -derivedDataPath build CODE_SIGN_IDENTITY=- build
open build/Build/Products/Release
```

## Release

Push a version tag. GitHub Actions (`.github/workflows/release.yml`) builds the app, creates a DMG, and publishes it to Releases.

```sh
git tag v1.0.0
git push origin v1.0.0
```

The version in the tag (without `v`) becomes the app version.

## First-time setup

1. From the dialog shown on first launch, open System Settings > Privacy & Security > Accessibility and allow CmdKana. Until you allow it, the menu bar shows a warning icon, and 「アクセシビリティを許可…」 (Allow Accessibility…) in its menu opens the setting. Once you allow it, CmdKana relaunches itself and the icon changes to か in a square.
2. To launch automatically, turn on 「ログイン時に起動」 (Launch at Login) from the か icon in the menu bar.

If you used ⌘英かな before, quit it and remove it from the Accessibility list to avoid conflicts.

## How it works

| Role | API |
| --- | --- |
| Menu bar app | SwiftUI `MenuBarExtra` + `LSUIElement` |
| Detecting ⌘ keys | `CGEvent.tapCreate` (listen-only event tap) |
| Switching input | Posts events for the JIS Eisu key (`kVK_JIS_Eisu`) and Kana key (`kVK_JIS_Kana`) |
| Launch at login | `SMAppService.mainApp` |

Instead of selecting an input source directly, the app posts the same events as pressing the Eisu or Kana key. This lets it work with any Japanese input method, such as the built-in Japanese input or Google Japanese Input.

## Files

```
CmdKana/
├── AppIcon.icon      # App icon (Icon Composer)
├── CmdKanaApp.swift  # App entry point and menu bar UI
└── KeyMonitor.swift  # Detects ⌘ keys and posts Eisu / Kana key events
```

## Uninstall

1. Turn off 「ログイン時に起動」 (Launch at Login) in the menu, then choose 「終了」 (Quit).
2. Delete `/Applications/CmdKana.app`.
3. Remove CmdKana from System Settings > Privacy & Security > Accessibility.
