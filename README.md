# Agent Native Claude Code Plugins

Claude Code用の品質ガード・設計・実装スキル集。

---

## インストール（ワンライナー）

```bash
curl -fsSL https://raw.githubusercontent.com/agent-native-ai/claude-plugins/main/install.sh | bash
```

これだけ。更新時も同じコマンドを再実行するだけ。

---

## 手動インストール

```bash
git clone https://github.com/agent-native-ai/claude-plugins.git
cd claude-plugins/plugins
mkdir -p ~/.claude/skills
for skill in */skills/*/; do
  name=$(basename "$skill")
  cp -r "$skill" ~/.claude/skills/
done
```

---

## 確認

```bash
claude
```

起動後に `/super-plan` と入力して発動すればOK。

---

## スキル一覧（13種）

### Security

| スキル | 説明 |
|--------|------|
| security-audit | 3段階セキュリティ監査（パターンスキャン + 依存関係 + AI攻撃者分析） |

### Development

| スキル | 説明 |
|--------|------|
| auto-test | テストフレームワーク自動検知・実行 |
| pre-check | タスク開始前の影響範囲・品質基準チェック |
| quality-rules | 実装中の品質基準参照・自動適用 |
| rapid-build | 承認済み設計書をconfig-first・品質ゲート付きで実行 |
| multi-agent | 大規模タスクをAgent Teamsで並列実行 |

### Planning

| スキル | 説明 |
|--------|------|
| super-plan | エビデンスベースの設計書作成（リサーチ→設計→承認ゲート） |

### Operations

| スキル | 説明 |
|--------|------|
| meeting-prep | 面談・MTG前のブリーフィング / アジェンダ自動生成 |
| incident-triage-lite | インシデントログ作成 + 類似インシデント検索 |

### Design

| スキル | 説明 |
|--------|------|
| frontend-slides | ゼロ依存HTMLプレゼンテーション生成（12プリセット + PPT変換） |
| presentation-architect | 会社説明資料・提案書・ピッチデッキのオーケストレーター |

### Meta

| スキル | 説明 |
|--------|------|
| neo-skill-creator | Q1-Q10品質基準を満たすスキルを作成 |
| leak-learner | レビュアー指摘を半自動で学習し品質ルールに還流 |

---

## 注意事項

- **`claude install` は使わない** — CLI本体のバージョン更新コマンドであり、スキルインストール機能ではありません
- スキルは `~/.claude/skills/` にファイルを置くだけで動きます
- アンインストール: `rm -rf ~/.claude/skills/{skill-name}`
