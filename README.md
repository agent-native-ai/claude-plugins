# Agent Native Claude Code Plugins

Claude Codeの設計・実装・セキュリティワークフローを強化するスキルパック。

---

## インストール（ワンライナー）

```bash
curl -fsSL https://raw.githubusercontent.com/agent-native-ai/claude-plugins/main/install.sh | bash
```

11スキルが一括インストールされます。更新時も同じコマンドを再実行するだけ。

---

## 全体像

```
                        ┌─────────────────────────────────────┐
                        │           ワークフロー                │
                        │                                     │
  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
  │pre-check │ → │super-plan│ → │rapid-build│ → │auto-test │  │
  │(リスク)   │   │(設計)     │   │(実装)     │   │(テスト)   │  │
  └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
                                     ↑               ↓       │
                              quality-rules    security-audit │
                              (実装中ずっと)    (最終監査)      │
                        └─────────────────────┼───────────────┘
                                              │
                        ┌─────────────────────┼───────────────┐
                        │  security-audit が自動連携（DELEGATE） │
                        │                                     │
                        │  audit-context-building  Phase 0    │
                        │  insecure-defaults       Phase 1    │
                        │  sharp-edges             Phase 1    │
                        │  semgrep                 Phase 2    │
                        │  codeql                  Phase 2    │
                        └─────────────────────────────────────┘
```

---

## スキル一覧（11種）

### Core Skills（6種）

| スキル | 役割 | コマンド |
|--------|------|---------|
| super-plan | 設計書作成（リサーチ→設計→承認） | `/super-plan` |
| rapid-build | 設計書→実装（品質ゲート付き） | `/rapid-build` |
| quality-rules | 実装中の品質基準チェック | 自動適用 |
| pre-check | 着手前のリスクスキャン | `/pre-check` |
| security-audit | セキュリティ監査（3段階） | `/security-audit` |
| auto-test | テスト自動検知・実行 | `/auto-test` |

### Security Extension Skills（5種）

`security-audit` が自動的に呼び出して精度を向上させるスキル。

| スキル | 連携フェーズ | 効果 |
|--------|------------|------|
| audit-context-building | Phase 0 | 行レベルのコード分析コンテキスト構築 |
| insecure-defaults | Phase 1 | fail-open設定・ハードコードシークレット検出 |
| sharp-edges | Phase 1 | 危険API・フットガン設計検出 |
| semgrep | Phase 2 | 静的解析スキャン（複数言語対応） |
| codeql | Phase 2 | 汚染追跡・データフロー分析 |

---

## 確認

```bash
claude
```

起動後に `/super-plan` と入力して発動すればOK。

---

## アンインストール

```bash
rm -rf ~/.claude/skills/{super-plan,rapid-build,quality-rules,pre-check,security-audit,auto-test,audit-context-building,insecure-defaults,sharp-edges,semgrep,codeql}
```

---

## 注意

- **`claude install` は使わない** — CLI本体の更新コマンドであり、スキル用ではない
- スキルは `~/.claude/skills/` にファイルを置くだけで動く
- 更新: ワンライナーを再実行するだけ（上書きインストール）
