# Agent Native Claude Code Plugins

Claude Codeの設計・実装ワークフローを強化するスキルパック。

---

## インストール（ワンライナー）

```bash
curl -fsSL https://raw.githubusercontent.com/agent-native-ai/claude-plugins/main/install.sh | bash
```

更新時も同じコマンドを再実行するだけ。

---

## スキル一覧（6種）

| スキル | 役割 | コマンド |
|--------|------|---------|
| super-plan | 設計書作成（リサーチ→設計→承認） | `/super-plan` |
| rapid-build | 設計書→実装（品質ゲート付き） | `/rapid-build` |
| quality-rules | 実装中の品質基準チェック | 自動適用 |
| pre-check | 着手前のリスクスキャン | `/pre-check` |
| security-audit | セキュリティ監査（3段階） | `/security-audit` |
| auto-test | テスト自動検知・実行 | `/auto-test` |

### ワークフロー

```
pre-check → super-plan → rapid-build → auto-test → security-audit
  (リスク)    (設計)       (実装)       (テスト)     (監査)
                            ↑
                      quality-rules（実装中ずっと適用）
```

---

## 確認

```bash
claude
```

起動後に `/super-plan` と入力して発動すればOK。

---

## アンインストール

```bash
rm -rf ~/.claude/skills/{super-plan,rapid-build,quality-rules,pre-check,security-audit,auto-test}
```

---

## 注意

- `claude install` は使わない（CLI本体の更新コマンドであり、スキル用ではない）
- スキルは `~/.claude/skills/` にファイルを置くだけで動く
