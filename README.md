# PNG to PDF 変換ツール

macOS用のPNG画像をPDFに一括変換するAppleScriptツールです。v2.0では200MB自動分割機能を搭載し、大容量ファイル処理にも対応しています。

## 📁 プロジェクト構造

```
PNG_to_PDF/
├── README.md                    # このファイル
├── CLAUDE.md                    # Claude Code用プロジェクト情報
├── versions/                    # バージョン管理フォルダ
│   ├── v1.0_basic/             # v1.0 基本版
│   │   ├── main.scpt           # 実行ファイル
│   │   ├── main.applescript    # ソースコード
│   │   └── VERSION_INFO.md     # バージョン詳細
│   └── v2.0_split_feature/     # v2.0 分割機能版 ⭐ 推奨
│       ├── main.scpt           # 実行ファイル（200MB分割対応）
│       ├── main.applescript    # ソースコード
│       └── VERSION_INFO.md     # バージョン詳細
├── docs/                       # ドキュメント
│   ├── PNG_to_PDF_仕様書.md    # 統合仕様書
│   └── 200MB分割機能_説明書.md  # v2.0新機能詳細
└── temp/                       # 一時ファイル用（作業時のみ）
```

## 🚀 クイックスタート

### 最新版（v2.0）の使用方法

1. **前提条件の確認**
   ```bash
   # ImageMagickのインストール
   brew install imagemagick
   ```

2. **スクリプトの実行**
   ```bash
   # v2.0（200MB分割対応版）を実行
   osascript versions/v2.0_split_feature/main.scpt
   ```

3. **ダイアログに従って操作**
   - PDFファイル名を入力
   - 変換設定を確認
   - 完了後、PNG削除の可否を選択

## 📋 バージョン比較

| 機能 | v1.0 基本版 | v2.0 分割版 |
|------|-------------|-------------|
| PNG→PDF変換 | ✅ | ✅ |
| 一括処理 | ✅ | ✅ |
| GUI操作 | ✅ | ✅ |
| ファイルサイズ制限 | ❌ | ✅ 200MB |
| 自動分割 | ❌ | ✅ |
| 進捗表示 | ❌ | ✅ |
| エラーハンドリング | 基本 | 強化 |

## 🔧 設定

### 共通設定（両バージョン）
- **ソースフォルダ**: `/Users/gantaku/本/_screenshot/`
- **保存フォルダ**: `/Users/gantaku/本/`
- **画像品質**: 85%
- **ページサイズ**: A4

### v2.0限定設定
- **最大ファイルサイズ**: 200MB（変更可能）
- **分割命名形式**: `filename_part1.pdf`, `filename_part2.pdf`

## 📖 詳細ドキュメント

### 📚 完全な仕様書
[`docs/PNG_to_PDF_仕様書.md`](docs/PNG_to_PDF_仕様書.md) - 全機能の詳細仕様

### 🆕 v2.0新機能解説
[`docs/200MB分割機能_説明書.md`](docs/200MB分割機能_説明書.md) - 分割機能の技術詳細

### 🔍 バージョン詳細
- [`versions/v1.0_basic/VERSION_INFO.md`](versions/v1.0_basic/VERSION_INFO.md) - v1.0詳細
- [`versions/v2.0_split_feature/VERSION_INFO.md`](versions/v2.0_split_feature/VERSION_INFO.md) - v2.0詳細

## 💡 使用例

### 基本的な使用（v2.0推奨）
```bash
# 最新版の実行
osascript versions/v2.0_split_feature/main.scpt
```

### 旧バージョンの使用（互換性確認時など）
```bash
# v1.0の実行
osascript versions/v1.0_basic/main.scpt
```

## 🔄 v1.0からv2.0への移行

### 互換性
- **完全下位互換**: v1.0と同じ操作で使用可能
- **設定継承**: 既存設定はそのまま使用
- **小規模処理**: v1.0と同等の動作

### 新機能の恩恵
- 大量画像処理時の安定性向上
- メール添付制限（25MB等）への自動対応
- クラウドストレージ効率化

## ⚠️ 重要な注意点

### システム要件
- **OS**: macOS（AppleScript対応）
- **依存ソフト**: ImageMagick（Homebrew推奨）
- **権限**: ファイルアクセス権限

### 制限事項
- **単一ファイル制限**: 1つのPNGで200MB超過の場合は分割不可
- **パス固定**: ソース・保存フォルダはスクリプト内で固定
- **macOS専用**: 他OSでは動作不可

## 🔮 今後の開発予定

- [ ] 設定ファイル対応（パス設定の外部化）
- [ ] 分割サイズのカスタマイズ機能
- [ ] プログレスバー改善
- [ ] ドラッグ&ドロップ対応
- [ ] 多言語対応

## 📞 サポート

### トラブルシューティング
1. **ImageMagick未検出**: `brew install imagemagick`で再インストール
2. **フォルダ不存在**: 指定パスの確認と作成
3. **権限エラー**: macOSのプライバシー設定を確認

### 設定変更
スクリプト内の設定値を直接編集することで、フォルダパスや分割サイズを変更可能です。

---

**推奨**: 最新の安定版として **v2.0 分割機能版** の使用を推奨します。