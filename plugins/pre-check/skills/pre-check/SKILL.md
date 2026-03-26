---
name: risk-scan
description: "Zero Leak L1: タスク開始前に影響範囲・品質基準・過去インシデントを洗い出す。「戦場の地図」を作ってからL2に渡す。"
---

# Pre-Check — Zero Leak L1（作業開始前）

タスクを始める前に「何を確認すべきか」を先に洗い出す。

## トリガー

**自動:**
- 全てのタスク開始時（コード変更・資料作成・修正指示）
- super-plan承認後、rapid-build開始前

**L1はバックグラウンドで素早く実行。** ownerを待たせない。

## 手順

### Step 1: 影響範囲の特定

```
ownerの指示を解析 → 影響するファイル/モジュールを特定
  ↓
Glob + Grep で関連ファイルをリスト化
  ↓
出力: 影響ファイルリスト（L3 review-guardが全量チェック時に使用）
```

### Step 2: 品質基準の読み込み

```
1. .claude/quality-rules.yaml（Global rules）
2. skills/{current-skill}/lessons/*.md（Skill lessons — あれば）
3. Session memory（同セッション内のowner指摘 — あれば）
  ↓
出力: 今回のタスクに適用すべきルールリスト（L2が参照）
```

### Step 3: 過去インシデント照合

```
Grep: INCIDENT_REPORT_*.md + DECISION_*.md で関連キーワード検索
  ↓
出力:
  - 過去の同種インシデント: N件
  - 関連する意思決定: N件
  - 過去に同様の修正で再発したパターン: N件
```

### Step 4: ownerへの簡潔な報告

```
影響範囲 N件、適用ルール N件、過去インシデント N件で開始します
```

### Step 4.5: 受け入れ条件カード生成（BLOCKING — コンテキスト希釈ガード）

**目的**: 長時間タスクで受け入れ条件がコンテキストから消失する問題を防止する。
条件を外部ファイルに永続化し、L3 review-guardとship-itが照合に使う。

**研究根拠**: Lost in the Middle（中央の情報20%無視）+ Context Length Alone Hurts（長さだけで13-85%劣化）

#### 4.5a: task_id発番

```
task_id = YYYYMMDD-HHMM-{slug}
例: 20260326-1430-harness-v2
```

#### 4.5b: artifact_type判定

| 判定ステップ | ロジック | 結果 |
|---|---|---|
| 1. diffの拡張子を分類 | `*.html, *.css, *.tsx, *.jsx, *.svelte, *.vue` を含む → `ui_visual`候補。`*.py, *.ts, *.js`のみ（tsx/jsx除く）→ `code`候補。`*.md`のみ → `document`候補。SKILL.md → `skill_modification`候補 | 候補値 |
| 2. 複合diffの場合 | HTML+PY等が混在 → **安全側: `ui_visual`**（4軸スコアリング適用方向） | 最も厳しい候補 |
| 3. super-plan設計書あり | 設計書のartifact_typeフィールドを採用 | 設計書の値を優先 |
| 4. owner明示 | 「これはUI」「コードだけ」等 → owner指定を最優先 | owner値で上書き |
| 5. 判定不能 | → **デフォルト: `code`** | 安全側デフォルト |

#### 4.5c: acceptance state生成

ownerの指示・設計書のdone_criteriaから受け入れ条件を抽出し、以下のschemaでファイルを生成:

**保存先**: `.claude/state/acceptance/{task_id}.yaml`

```yaml
task_id: "{task_id}"
created_at: "{ISO 8601}"
artifact_type: "{ui_visual|code|document|skill_modification}"
artifact_paths:
  - "{成果物パス1}"
  - "{成果物パス2}"
retention: task  # session | task | permanent

criteria:
  - id: AC001
    text: "{条件文（機能要件のみ。ビジネス数値はプレースホルダー化）}"
    type: permanent  # permanent | temporary
    status: unknown  # unknown | pass | fail
    verified_by: null  # review-guard | ship-it | owner
    verification_method: null  # "test -f" | "grep" | "checklist" | "manual"
    evidence_ref: null  # "filesystem:/path" | "grep:pattern:count" | "section:N"
    verified_at: null
```

#### 4.5d: 機密除外ルール

条件文の生成時に以下のパターンを検出し、テンプレート化（固有値→プレースホルダー）:
- **固有名詞**: `biz_clients/` 配下のクライアント名 → `{client_name}`
- **数値列**: 金額・KPI値（例: 「82件→9名」→ `{target}件→{result}名`）
- **メール/URL/Slack ID**: HC001-HC005パターンと同じ検出ロジック

#### 4.5e: ownerへの出力（skill-preflight対象）

```
受け入れ条件カード:
  task_id: {task_id}
  artifact_type: {type}
  条件:
  - [ ] AC001: {条件文}
  - [ ] AC002: {条件文}
  保存先: .claude/state/acceptance/{task_id}.yaml
```

**失敗時**: ownerの指示から条件を抽出できない → STOP + 「完了条件を明確にしてください」

## 連携

| スキル | 関係 |
|---|---|
| quality-rules (L2) | L1の出力（適用ルールリスト）をL2が参照 |
| review-guard (L3) | L1の出力（影響ファイルリスト）をL3が全量チェック時に使用 |
| super-plan | super-planのAgent B出力がL1の過去インシデント検索を補完 |
## 設計原則

| 原則 | 出典 | 適用 |
|------|------|------|
| 先に地図を作る | Shift-Left原則 | 実装前に影響範囲・品質基準・過去インシデントを洗い出す |
| バックグラウンド実行 | ユーザー体験最優先 | ownerを待たせない。素早く完了して結果を1行で報告 |
| 機械的検索 | DRY / 再現性 | Glob+Grepで影響範囲を機械的に特定。記憶や推測に頼らない |

## Config

| カテゴリ | キー | デフォルト値 | 説明 |
|---------|------|------------|------|
| パス | quality_rules |  | Global rulesファイル |
| パス | incidents_dir |  | インシデント検索先 |
| パス | decisions_dir |  | 意思決定検索先 |
| 検索 | incident_pattern |  | インシデントファイル名パターン |
| 検索 | decision_pattern |  | 意思決定ファイル名パターン |
| state | acceptance_state_dir | `.claude/state/acceptance/` | acceptance state保存先 |
| state | task_id_format | `YYYYMMDD-HHMM-{slug}` | task_id発番形式 |

## セキュリティ

該当なし -- ローカルファイルの読み取りのみ。外部API・認証なし。

## BLOCKINGゲート

| ステップ | 失敗条件 | 動作 |
|---------|---------|------|
| Step 1 | ownerの指示が曖昧で影響範囲を特定できない | STOP + ownerに確認: 「どのファイル/モジュールが対象ですか？」 |
| Step 2 | quality-rules.yamlが存在しない | 続行: Global rulesなしで実行（Skill lessons + Session memoryのみ） |
| Step 3 | incidents/knowledge/ディレクトリが存在しない | 続行: 過去インシデント0件として報告 |
| Step 4.5 | ownerの指示から完了条件を抽出できない | STOP + ownerに確認: 「完了条件を明確にしてください」 |
| Step 4.5 | .claude/state/acceptance/ ディレクトリが存在しない | 自動作成して続行 |

## エスカレーション

| 状況 | 対応 |
|------|------|
| 影響ファイルが20件以上 | ownerに確認: 「影響範囲が広い（{N}件）。段階的に進めますか？」 |
| 過去の同種インシデントが3件以上 | ownerに報告: 「同種インシデントが{N}件。再発パターンの可能性あり」 |
| 適用ルールが矛盾している | ownerに確認: 「ルール{A}と{B}が矛盾。どちらを優先しますか？」 |

## 汎用性

検索パス・ファイル名パターンはConfig表で外部化済み。企業固有値なし。

## 連携

| スキル | 関係 | 説明 |
|--------|------|------|
| quality-rules (L2) | L1の出力（適用ルールリスト）をL2が参照 | - |
| review-guard (L3) | L1の出力（影響ファイルリスト + acceptance state）をL3が照合時に使用 | - |
| ship-it | L1の出力（artifact_type + task_id）をship-itが反復プロファイル選択とearly exit判定に使用 | - |
| super-plan | super-planのAgent B出力がL1の過去インシデント検索を補完。設計書のartifact_typeを優先採用 | - |
## やらないこと

- 品質チェックの実行（L2, L3の領域）
- ルールの作成・変更（L5の領域）
- 実装そのもの

> lessons/ ディレクトリで leak-learner (L5) と間接接続。直接CALLではない。
