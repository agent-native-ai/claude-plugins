# Agent Native Claude Code Plugins

社内用Claude Code品質ガードスキル。

## セットアップ

### 1. マーケットプレイス追加
```
/plugin marketplace add agent-native-ai/claude-plugins
```

### 2. プラグインインストール
```
/plugin install security-audit@agent-native
/plugin install auto-test@agent-native
/plugin install pre-check@agent-native
/plugin install quality-rules@agent-native
```

## プラグイン一覧

| プラグイン | 説明 |
|-----------|------|
| security-audit | 3段階セキュリティ監査 |
| auto-test | テストフレームワーク自動検知・実行 |
| pre-check | タスク開始前の影響範囲チェック |
| quality-rules | 実装中の品質基準参照 |

## 更新
```
/plugin marketplace update agent-native
```
