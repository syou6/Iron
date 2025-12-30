# Nan Ton? - 開発ガイド

## プロジェクト概要

**Nan Ton?**（何トン?）は、Strongerにインスパイアされた日本語ネイティブの筋トレ記録アプリです。
Ironオープンソースプロジェクトをベースに、日本のユーザー向けに最適化しています。

## 技術スタック

- **言語**: Swift
- **UI**: SwiftUI
- **最小iOS**: 16.0
- **データベース**: CoreData
- **チャート**: DGCharts 5.x
- **アーキテクチャ**: MVVM

## プロジェクト構成

```
Iron/
├── Iron/                    # メインアプリ
│   ├── UI/                  # SwiftUI Views
│   │   ├── Feed/            # ホーム画面・アクティビティ
│   │   ├── History/         # ワークアウト履歴
│   │   ├── Workout/         # ワークアウト記録
│   │   └── Settings/        # 設定画面
│   └── ...
├── Shared/                  # 共有コード
│   ├── Data/                # データモデル・ストア
│   └── Extension/           # 拡張
├── WorkoutDataKit/          # ワークアウトデータフレームワーク
│   └── Model/               # CoreDataモデル
├── IronWatch/               # Apple Watchアプリ
└── IronWidget/              # ウィジェット
```

## Bundle ID・識別子

- **Bundle ID**: `com.shodev.nanton`
- **App Group**: `group.com.shodev.nanton`
- **iCloud Container**: `iCloud.com.shodev.nanton`

## コア機能

### 必須機能（MVP）
- [x] ワークアウト記録（重量・レップ・セット）
- [x] ルーティン/テンプレート作成
- [x] 休憩タイマー
- [x] 進捗グラフ・統計
- [x] 1RM計算
- [x] 種目データベース（組み込み種目）
- [x] カスタム種目作成
- [x] iCloudバックアップ

### 追加機能
- [x] Apple Watch連携
- [x] Apple Health連携
- [ ] ウィジェット対応
- [ ] ワークアウト共有機能

## 料金モデル

**フリーミアム**
- 基本機能: 無料
- プレミアム機能: 有料（サブスクまたは買い切り）

### 有料機能候補
- 詳細な統計・分析
- 無制限のルーティン作成
- データエクスポート
- 広告非表示

## UI/UXガイドライン

### 言語
- **完全日本語対応**
- UI要素はすべて日本語
- 種目名も日本語（ベンチプレス、スクワット等）

### デザイン原則
1. **シンプル**: 必要な情報だけを表示
2. **高速**: ワークアウト中の操作は最小限に
3. **直感的**: 初心者でも迷わない
4. **モダン**: iOS標準のデザインパターンに準拠

### カラースキーム
- アクセントカラー: システムデフォルト（ユーザー設定可）
- ダークモード: 完全対応

## 開発フェーズ

### Phase 0: 環境構築 ✅
- [x] Bundle ID変更
- [x] iOS 16+ターゲット設定
- [x] Charts → DGCharts移行

### Phase 1: 日本語化 ✅
- [x] UI文字列の日本語化
- [x] データモデルの日本語化
- [x] エラーメッセージの日本語化

### Phase 2: 種目データベース日本語化
- [ ] 組み込み種目名の日本語化
- [ ] 筋肉部位名の日本語化
- [ ] 種目説明の日本語化

### Phase 3: UI/UX改善
- [ ] デザインリフレッシュ
- [ ] オンボーディング画面
- [ ] 操作性の改善

### Phase 4: 有料機能実装
- [ ] サブスクリプション/課金システム
- [ ] プレミアム機能の実装

### Phase 5: App Store申請
- [ ] App Store Connect設定
- [ ] スクリーンショット作成
- [ ] 説明文・キーワード
- [ ] プライバシーポリシー
- [ ] 審査申請

## コーディング規約

### Swift
- Swift標準のコーディングスタイル
- 変数名・関数名は英語（camelCase）
- コメントは日本語OK

### SwiftUI
- Viewは小さく保つ（200行以内目安）
- 再利用可能なコンポーネントは分離
- プレビューを活用

### CoreData
- モデル変更時はマイグレーション必須
- `saveOrCrash()`でエラーハンドリング

## よく使うコマンド

```bash
# ビルド
xcodebuild -scheme Iron -configuration Debug build

# テスト
xcodebuild -scheme Iron -configuration Debug test
```

## 重要なファイル

| ファイル | 説明 |
|---------|------|
| `Iron/UI/Workout/CurrentWorkoutView.swift` | ワークアウト記録メイン画面 |
| `Iron/UI/Feed/FeedView.swift` | ホーム画面 |
| `Iron/UI/Settings/SettingsView.swift` | 設定画面 |
| `WorkoutDataKit/Model/` | CoreDataモデル |
| `Shared/Data/Model/WeightUnit.swift` | 重量単位設定 |

## 注意事項

- Apple Health連携はシミュレータでは動作しない
- iCloudバックアップのテストには実機が必要
- Apple Watch機能は実機ペアリングが必要

## リンク

- ベースプロジェクト: [Iron (GitHub)](https://github.com/kabouzeid/Iron)
- DGCharts: [DGCharts (GitHub)](https://github.com/ChartsOrg/Charts)
