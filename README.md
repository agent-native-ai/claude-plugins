# Agent Native Claude Code Plugins

Claude Code品質ガード・設計・実装・学習スキル。

## セットアップ

### 1. マーケットプレイス追加
```
/plugin marketplace add agent-native-ai/claude-plugins
```

### 2. プラグインインストール
```
/plugin install <plugin-name>@agent-native
```

## プラグイン一覧（13種）

### Security

| プラグイン | 説明 |
|-----------|------|
| security-audit | 3段階セキュリティ監査（パターンスキャン + 依存関係 + AI攻撃者分析） |

### Development

| プラグイン | 説明 |
|-----------|------|
| auto-test | テストフレームワーク自動検知・実行 |
| pre-check | タスク開始前の影響範囲・品質基準チェック |
| quality-rules | 実装中の品質基準参照・自動適用 |
| rapid-build | 承認済み設計書をconfig-first・品質ゲート付きで実行 |
| multi-agent | 大規模タスクをAgent Teamsで並列実行 |

### Planning

| プラグイン | 説明 |
|-----------|------|
| super-plan | エビデンスベースの設計書作成（リサーチ→設計→承認ゲート） |

### Operations

| プラグイン | 説明 |
|-----------|------|
| meeting-prep | 面談・MTG前のブリーフィング / アジェンダ自動生成 |
| incident-triage-lite | インシデントログ作成 + 類似インシデント検索 |

### Design

| プラグイン | 説明 |
|-----------|------|
| frontend-slides | ゼロ依存HTMLプレゼンテーション生成（12プリセット + PPT変換） |
| presentation-architect | 会社説明資料・提案書・ピッチデッキのオーケストレーター |

### Meta

| プラグイン | 説明 |
|-----------|------|
| neo-skill-creator | Q1-Q10品質基準を満たすスキルを作成 |
| leak-learner | レビュアー指摘を半自動で学習し品質ルールに還流 |

## 更新
```
/plugin marketplace update agent-native
```
