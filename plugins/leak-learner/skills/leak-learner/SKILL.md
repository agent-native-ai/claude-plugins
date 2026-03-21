---
name: leak-learner
description: "チーム内の指摘・フィードバックを半自動で学習し、品質ルールに還流する。hooks自動記録→session-end候補生成→リーダー承認→quality-rules/lessons反映。完全自動にしない理由: 誤学習永続化・Reward Hacking・ルール肥大化の3リスク（Reflexion/METR/Claude Code公式）"
---

# Leak Learner — 半自動学習ループ

レビュアー・リーダーの指摘から学習し、品質ルールを育てる。**完全自動ではなくリーダー承認を挟む。**

## 設計思想

```
❌ V2.1: 指摘 → AI自動でルール追加（3リスク: 誤学習・Reward Hacking・肥大化）
✅ V2.2: 指摘 → hook自動記録 → session-end候補生成 → リーダー承認 → 反映
```

**業界根拠**:
- Production AIの74%が人間評価に依存（Cleanlab 2025）
- 自己反省の質はフィードバックの質に依存（Reflexion研究）
- AIが評価基準をハックする（METR 2025）
- 150-200命令超でLLMの遵守率が急落（Claude Code公式）

## 4つのタイミング

### Step 1 (T1): hook自動記録

- **仕組み**: UserPromptSubmit hook（例: `learn-from-edits.sh`）
- **処理**: レビュアー/リーダーの修正発言をキーワード検出 → Config `corrections_file` に蓄積
- **AIの関与**: なし（hookが機械的に実行）

**検出キーワード例**: 「違う」「そうじゃない」「やめて」「禁止」「変えないで」「〜しない」「なんで〜した」「おかしい」「壊れてる」

### Step 2 (T2): セッション内適用（AI自発）

- **仕組み**: レビュアー/リーダーの指摘を検出したら、Session memoryに即追記
- **処理**: 同セッション内で再発防止
- **例**: レビュアー「赤使うな」→ Session memory: `TEMP_CL: 赤禁止`
- **注意**: AI自発性に依存。T1がセーフティネット

### Step 3 (T3): 学習候補生成（session-end hook）

- **仕組み**: session-end hook に追加
- **処理**: Config `corrections_file` → Config `candidates_file`（候補サマリー）
- **AIの関与**: なし（hookが機械的に実行）
- **ここでは候補を「生成」するだけ。適用はしない**

### Step 4 (T4): リーダー承認（人間ゲート）

- **仕組み**: 朝レポートまたは定期レビュー
- **処理**:
  1. Config `candidates_file` を提示
  2. リーダーが承認 / 修正 / 却下を判断
  3. 承認分のみ反映:
     - Global rule → Config `quality_rules` に追記
     - Skill lesson → skills/{name}/lessons/ に追記
     - プロセス改善 → `.claude/rules/` に追記
  4. 重複チェック → 既存ルールと重複していないかスキャン
  5. git commit

## リーダー承認なしにやってよいこと / やってはいけないこと

| 行動 | 承認 |
|------|------|
| corrections fileへの記録 | 不要（hookが自動） |
| Session memoryへの追記 | 不要（同セッション限定・揮発性） |
| candidates fileの生成 | 不要（hookが自動） |
| **quality-rules fileへの追記** | **リーダー承認必須** |
| **lessons/への永続的追記** | **リーダー承認必須** |
| **.claude/rules/への追記** | **リーダー承認必須** |

## 衝突解決ポリシー

```
Client/Project lessons > Skill lessons > Global rules（具体的が優先）
例外: security / hardcode カテゴリは常にGlobal最優先（上書き不可）
```

## 連携

| スキル | 関係 | 説明 |
|--------|------|------|
| quality-rules | 還流先 | リーダー承認後にルールを追加 |
| pre-check | 入力 | pre-checkの捕捉結果を学習候補に含める |

## 設計原則

| 原則 | 出典 | 適用 |
|------|------|------|
| リーダー承認ゲート必須 | Reflexion研究 / METR 2025 | 永続的ルール変更はリーダー承認後のみ。誤学習の永続化を防止 |
| 半自動 > 完全自動 | Claude Code公式（150命令問題） | hook自動記録 + リーダー承認の2段階。完全自動にしない |
| 具体的が優先 | 衝突解決ポリシー | Client/Project lessons > Skill lessons > Global rules |

## Config

| カテゴリ | キー | デフォルト値 | 説明 |
|---------|------|------------|------|
| パス | corrections_file | `.claude/corrections.jsonl` | hook自動記録先 |
| パス | candidates_file | `.claude/learning-candidates.md` | 学習候補サマリー |
| パス | quality_rules | `.claude/quality-rules.yaml` | Global rulesのSSoT |
| 閾値 | max_global_rules | `50` | Global rules上限。超過時はアーカイブ |
| 閾値 | max_instructions | `150` | LLM命令上限（遵守率急落の閾値） |

## セキュリティ

| 項目 | ルール |
|------|--------|
| ルール変更権限 | リーダー承認なしにquality-rules / lessons/ / .claude/rules/ を変更しない |
| Session memory | 同セッション限定・揮発性。永続化はT4のリーダー承認後のみ |

## BLOCKINGゲート

| ステップ | 失敗条件 | 動作 |
|---------|---------|------|
| T1: hook記録 | corrections file書き込み失敗 | 警告ログ出力。T2以降は続行 |
| T4: リーダー承認 | リーダーが却下 | 該当候補を破棄。quality-rulesに追記しない |
| T4: 重複チェック | 既存ルールと重複 | 重複を報告し、統合 or 破棄をリーダーに確認 |
| T4: 上限チェック | Global rulesが50件超過 | アーカイブ候補を提示してリーダーに確認 |

## エスカレーション

| 状況 | 対応 |
|------|------|
| 学習候補が10件以上溜まっている | リーダーに確認: 「学習候補が{N}件あります。一括レビューしますか？」 |
| 同じパターンの指摘が3回以上 | リーダーに確認: 「同じ指摘が繰り返されています。Global ruleに昇格しますか？」 |
| 既存ルールと矛盾する候補 | リーダーに確認: 「既存ルール{ID}と矛盾します。どちらを優先しますか？」 |

## 汎用性

corrections fileのパス・quality-rulesのパス・ルール上限はConfig表で外部化済み。学習ループの仕組み自体は企業固有値なし。

他社は以下を変更するだけで使える:
1. Config の `corrections_file`, `candidates_file`, `quality_rules` を自社パスに変更
2. hook スクリプト（`learn-from-edits.sh`, `session-end.sh`）を自社環境に配置
3. 検出キーワードを自社の言語・文化に合わせて調整

## 他のスキルとの連携

| スキル | 関係 | 説明 |
|--------|------|------|
| quality-rules | 還流先 | リーダー承認後にルールを追加 |
| pre-check | 入力 | pre-checkの捕捉結果を学習候補に含める |
| neo-skill-creator | 初期接続 | 新スキル作成時にleak-learner接続を組み込む |
| super-plan | 還流 | 蓄積されたルール・lessonsが次回のsuper-plan実行時に自動反映 |
| rapid-build | 還流 | 品質ゲート実行時にlessonsを参照 |

## やらないこと

- リーダー承認なしにquality-rulesを変更する
- リーダー承認なしにlessons/に永続的に書き込む
- スキル内に独自の学習ロジックを組み込む（各スキルはlessons/を持つだけ）
- 150-200命令を超えるルール肥大化を許容する
