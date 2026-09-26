# CmdIME

左右の ⌘ キーで英数／かなを切り替える、macOS のメニューバー常駐アプリです。
[⌘英かな (cmd-eikana)](https://github.com/iMasanari/cmd-eikana) がメンテナンスされなくなったため、代わりとして必要最低限の機能だけを実装しました。

## 機能

- 左 ⌘ を単独で押して離す → 英数（英語入力）
- 右 ⌘ を単独で押して離す → かな（日本語入力）
- メニューバーに常駐し、Dock には表示されない
- ログイン時の自動起動（メニューから切り替え）

⌘ を押している間に他のキーやマウスを操作した場合は切り替えないので、⌘C などのショートカットには影響しません。

## 動作環境

- macOS 15 以降
- Xcode 16 以降（ビルドする場合）

## ビルドとインストール

1. `CmdIME.xcodeproj` を Xcode で開く
2. ターゲット CmdIME の Signing & Capabilities で Team を選択する
   - 署名が毎回変わるとアクセシビリティ権限がリセットされるため、Team の設定を推奨します
3. Product > Archive、またはビルドして生成された `CmdIME.app` を `/Applications` にコピーする
4. `CmdIME.app` を起動する

コマンドラインでビルドする場合:

```sh
xcodebuild -project CmdIME.xcodeproj -scheme CmdIME -configuration Release -derivedDataPath build build
open build/Build/Products/Release
```

## 初回設定

1. 初回起動時に表示されるダイアログから、システム設定 > プライバシーとセキュリティ > アクセシビリティ を開き、CmdIME を許可する（許可した後、約 1 秒で動作を始めます。再起動は不要です）
2. 自動起動したい場合は、メニューバーの ⌘ アイコンから「ログイン時に起動」をオンにする

以前 ⌘英かな を使っていた場合は、競合を防ぐため ⌘英かな を終了し、アクセシビリティの一覧からも削除してください。

## 仕組み

| 役割 | 使用 API |
| --- | --- |
| メニューバー常駐 | SwiftUI `MenuBarExtra` + `LSUIElement` |
| ⌘ キーの検出 | `CGEvent.tapCreate`（listen-only のイベントタップ） |
| 入力切り替え | JIS 配列の英数キー（`kVK_JIS_Eisu`）／かなキー（`kVK_JIS_Kana`）のイベントを送出 |
| ログイン時起動 | `SMAppService.mainApp` |

入力ソースを直接指定するのではなく、英数キー／かなキーを押したときと同じイベントを送るので、ことえり・Google 日本語入力などの IME の種類を問わず動作します。

## ファイル構成

```
CmdIME/
├── CmdIMEApp.swift   # アプリ本体とメニューバー UI
└── KeyMonitor.swift  # ⌘ キーの検出と英数／かなキーの送出
```

## アンインストール

1. メニューから「ログイン時に起動」をオフにして「終了」を選ぶ
2. `/Applications/CmdIME.app` を削除する
3. システム設定 > プライバシーとセキュリティ > アクセシビリティ から CmdIME を削除する
