---
name: rapid-build
description: 承認済み設計書を、ベースラインコード再利用・config-first強制・並列エージェント・モジュール別品質ゲート・最終セキュリティ監査で実行する。super-planの出力を入力とする。12-Factor App、Shift-Left Security、Unix再利用>再発明、SOLID原則に基づく。
---

# Rapid Build スキル

承認済み設計書を効率的に実行する: 既存コードをベースラインとしてコピーし、
config-firstを強制し、モジュールごとに品質ゲートを実行し、最後にセキュリティ監査を行う。

## 設計原則

| 原則 | 出典 | 適用 |
|------|------|------|
| 再利用 > 再発明 | Unix哲学 | 既存の動くコードをベースラインとしてコピー。ゼロから書かない |
| Config-First | 12-Factor App | 環境依存の全値をモジュール実装前に定義。ハードコード値を構造的に防止 |
| 品質ゲートはブロッキング | Shift-Left Testing | 全チェックをパスしないと次に進めない。助言ではなく構造的制約 |
| Shift-Left Security | OWASP | 実装中に軽量チェック（モジュール単位）+ 最後に包括的監査 |
| 独立なら並列 | 並行計算理論 | 独立タスクにはマルチエージェント。依存タスクにはシングルエージェント |

## トリガー

### 明示的
- 「build」「実装」「rapid-build」「プランを実行」「作って」

### 自動検知
- super-planの設計書が承認された直後
- 承認済み設計書があるが実装が未開始

## 前提条件

super-planのPLAN_TEMPLATE.md形式に従った承認済み設計書。
設計書に以下が必要:
- `depends_on`、`done_criteria`、`base_file` フィールド付きのYAMLタスク分解
- 設定戦略セクション
- セキュリティ & プライバシーセクション

プロジェクトにアダプタファイル（例: `rapid-build-adapter.md`）がある場合、
ここで読み込んでプロジェクト固有の品質ルールを適用する。

## ワークフロー

### Step 0: Deployment Target検証（BLOCKING）

設計書のSection 5.4「Deployment Target」を確認し、実装環境を検証する。
**このステップをパスしないと実装に入らない。**

```
1. 実装リポ:
   - 設計書に「実装リポ」が明記されているか？
   - 明記されていない → STOP → ownerに確認
   - 「拡販」「プロダクト」「チームアクセス」→ 共有リポ（biz_agent-native）
   - 「個人運用」「内部ツール」→ 個人リポ（ai-company）
   - 共有リポ → worktree必須（worktree-workflow.md参照）

2. テスト環境:
   - 外部通知（Slack/Email/Webhook）がある → テストチャネル必須
   - Slack → #通知テスト (C0ALSU92Y84) をデフォルトに設定
   - 本番チャネルへの送信はowner承認後のみ

3. データソースSSoT:
   - 設計書に「データソースSSoT」が明記されているか？
   - 対象リポ内のSSoTファイルを `Glob` で確認（個人リポのSSoTを流用しない）
   - 例: 共有リポのタスク管理 → project-tracker.md（共有リポ内）を使う
   - 例: 個人リポのタスク管理 → ACTIVE_TASKS.md（個人リポ内）を使う
   - **別リポのデータを「フィルタして使う」は対処療法。データソース自体を正しく選ぶ**

4. Secret/権限:
   - 必要なSecretがGitHub/環境に設定されているか `gh secret list` で確認
   - 不足 → 設定してから実装開始
```

> 背景: Project Pulse（2026-03-23）で「拡販=Agent Nativeプロダクト」と設計書に書きながら
> ai-company（個人リポ）に実装。Slack通知も#agent-dev（本番）に直接送信。
> 原因: 設計書にDeployment Targetセクションがなく、実装開始時の検証もなかった。

### Step 0.5: ベースライン構築（再利用 > 再発明）

設計書で `base_file` が指定されている各タスクについて:

```
cp {base_file} → {task.files[0]}
git add {task.files[0]}
git commit -m "scaffold: copy {base_file} as baseline for {task.name}"
```

**これが重要な理由:**
- 開発者はゼロから書くのではなく、動くコードを修正する
- 既存パターン（レスポンシブレイアウト、イベントハンドリング等）が既に含まれている
- UI/UXの差分が「省略」ではなく「明示的なdiff」になる

全コピーの成功を検証: 各ファイルに対して `test -f {file}`。

### Step 1: 設計書のパース

承認済み設計書から以下を抽出:
- `tasks[]` — 依存関係、ファイル、done_criteria、base_files付きのタスク一覧
- `config_strategy` — 外出しすべき値とその格納先
- `security_requirements` — モジュールごとのセキュリティ要件
- `quality_rules` — アダプタファイルから読み込んだ品質ルール（あれば）

### Step 2: 実行モード判定

タスク構造を分析し、3つのモードから選択:

```
parallelizable = depends_onが全て完了済みのタスク数
unique_dirs = 全タスクファイルにまたがるユニークなディレクトリ数

IF parallelizable <= 2 AND unique_dirs <= 1:
  → シングルエージェント実行（親セッションが直接実装）

ELSE:
  → Agent Teams実行（Builder↔QA↔Securityの自動ループ）
  → Builder数 = min(3, ceil(parallelizable / 3))
```

### Step 3: Config-First実行（BLOCKING）

設定タスク（通常はTask #1、依存関係なし）を特定し、**親セッションが**最初に実行する。
Config-Firstは全モードで親が担当（Teams起動前に完了させる）。

**BLOCKINGゲート: 設定ファイルが存在し、かつコミットされるまでTeams起動不可。**

```bash
test -f {config_path} && git log --oneline -1 -- {config_path}
```

設定ファイルが存在しない or コミットされていない → STOP。先に作成する。

### Step 4: タスク実行（Agent Teams方式）

#### シングルエージェントモード（2タスク以下）

親セッションが直接実装。品質ゲートも自分でチェック。従来通り。

#### Agent Teamsモード（3タスク以上）

**チーム構成:**

| メンバー | 名前 | 役割 | ツール |
|---------|------|------|-------|
| Builder-1〜N | `builder-1` | タスク実装。完了したらQAにSendMessage | Write, Edit, Bash, Read, Glob, Grep |
| QA | `qa` | 品質ゲート G1-G6 + アダプタ拡張。FAIL時はBuilderに修正依頼をSendMessage | Read, Grep, Bash |
| Security | `security` | 全タスクPASS後にセキュリティ監査。CRITICAL時はBuilderに修正依頼 | Read, Grep, Bash |

**起動:**
```
TeamCreate:
  team_name: "rapid-build-{設計書名}"
  members:
    - name: "builder-1", prompt: "タスク {task_ids} を実装せよ。完了したらSendMessage(to: qa, ...)で報告"
    - name: "builder-2", prompt: "タスク {task_ids} を実装せよ。..." （タスク数に応じて）
    - name: "qa", prompt: "Builderからの完了報告を受けたら品質ゲートG1-G6を実行。PASSならOK返信。FAILなら具体的な修正指示を返信。3回連続FAILなら親にエスカレーション"
    - name: "security", prompt: "QAから'全タスクPASS'を受けたらセキュリティ監査を実行。結果を親に報告"
```

**フロー（Builderが2名の場合）:**
```
親 → TeamCreate(builder-1, builder-2, qa, security)

builder-1: Task-1 実装
  → SendMessage(to: qa, "Task-1 done. files: [path1, path2]")

builder-2: Task-2 実装（builder-1と並列）
  → SendMessage(to: qa, "Task-2 done. files: [path3]")

qa: builder-1の報告を受信 → 品質ゲート実行
  → G2 FAIL: "line 42 にハードコードURL"
  → SendMessage(to: builder-1, "G2 FAIL: line 42 の https://... を config に移動せよ")

builder-1: 修正
  → SendMessage(to: qa, "Task-1 fixed")

qa: 再検査 → 全PASS
  → SendMessage(to: builder-1, "Task-1 PASS")

qa: 全タスクPASS確認
  → SendMessage(to: security, "全 N タスク品質ゲートPASS。セキュリティ監査開始")

security: 監査実行
  → CRITICAL 0件 → SendMessage(to: parent, "セキュリティ監査完了。CRITICAL:0 HIGH:0")
  → CRITICAL あり → SendMessage(to: builder-{担当}, "CRITICAL: {詳細}。修正せよ")
    → 修正後 → security再検査
```

**品質ゲートルール（QAメンバーのプロンプトに埋め込む）:**
```
Builderから完了報告を受けたら、以下を全て検査:

G1: 単一責任 — モジュールの責務は1つだけか？
G2: ハードコード値ゼロ — grep '#[0-9a-fA-F]{3,8}' と grep '[0-9]{2,}px' で検出
G3: ベースファイルdiff — base_fileがある場合、diffは最小限か？
G4: セキュリティ基本 — 設計書のセキュリティ要件が実装されているか？
G5: ファイル存在 — test -f {file} で全ファイル確認
G6: 完了基準 — done_criteriaを満たしているか？
+ アダプタ定義のG7以降（あれば）

判定:
  全PASS → SendMessage(to: builder, "PASS")
  FAIL → SendMessage(to: builder, "G{N} FAIL: {具体的な修正指示}")
  3回連続FAIL → SendMessage(to: parent, "ESCALATE: Task-{id} が3回連続FAIL。G{N}: {詳細}")
```

**git競合防止（BLOCKING）:**
- 各Builderのタスクは**異なるファイル**を編集する（Step 1のタスク分配で保証）
- Builderはファイル編集後、`git add {自分のファイルのみ}` + `git commit` を実行
- `git add .` / `git add -A` 禁止（他Builderの変更を巻き込む）
- QAがPASS判定を出すまでBuilderはmainにマージしない

**ロールバック戦略**: Teams起動前に `git tag rapid-build/start` を打つ。
エスカレーション時: `git diff rapid-build/start..HEAD` で差分を確認し、ownerに判断を仰ぐ。

### Step 5: セキュリティ監査（Securityメンバー担当）

QAから「全タスクPASS」を受信後、Securityメンバーが自動実行:
- 設計書のセキュリティ & プライバシーセクションの全要件を検証
- 全ファイルにわたるハードコード値の最終スキャン
- 依存関係の脆弱性チェック（該当する場合）
- CRITICAL発見時: 担当Builderに直接修正依頼（親の中継不要）

### Step 6: 検証 + 完了

Security監査完了後、親セッションが最終検証:

1. **ビルド/テスト**: プロジェクトのビルド・テストコマンドを実行
2. **成果物検証**: 全タスクの全ファイルに対して `test -f`
3. **完了基準監査**: 全タスクのdone_criteriaを再検証
4. **最終レポート**:

```
rapid-build 完了:
- タスク: X/X 完了
- 品質ゲート: 全パス（修正ループ: 平均Y回/タスク）
- セキュリティ監査: CRITICAL 0 / HIGH 0 / MEDIUM X / LOW X
- ビルド: 成功
- 成果物: {作成/変更されたファイル一覧}
- 実行モード: Agent Teams (Builder×N + QA + Security)
```

## エスカレーション

| 状況 | 対応 |
|------|------|
| 設計書のYAMLタスク分解がパースできない | STOP → ownerに確認:「設計書の{セクション}が不明瞭です。base_file/depends_on/done_criteriaを明記してください」 |
| ベースラインファイルが存在しない | STOP → ownerに確認:「{base_file}が見つかりません。正しいパスを教えてください」 |
| 品質ゲート失敗が3回連続（同一タスク） | STOP → ownerに確認:「{タスク名}のG{N}が3回失敗。設計書の要件を緩和しますか？」 |
| セキュリティ監査でCRITICALが検出された | STOP → ownerに確認:「CRITICAL脆弱性を検出。修正してからデプロイしますか、リスク受容しますか？」 |
| マルチエージェントのチームメイトが応答しない | シングルエージェントにフォールバックして続行 |

## 連携

| 連携スキル | 関係 | トリガー |
|-----------|------|---------|
| execution-strategy | 前工程 | 推奨方式に応じて起動。cmux/シングルエージェント推奨時にrapid-buildが選択される |
| parallel-tasks | 並列実行 | 並列実行が有益な場合にrapid-buildから呼び出される |
| security-scan | Step 6 | 包括的スキャンのためにrapid-buildから呼び出される |
| test-runner | Step 7 | ビルド/テスト実行時に自動テストスキルを利用 |
| review-guard | 統合 | L3がStep 4の品質ゲートと統合。確定的チェッカーを共有 |

## このスキルがやらないこと

- 設計書を作ること（それはsuper-planの仕事）
- 承認済み設計書なしに開始すること
- 「デモだから」品質ゲートをスキップすること
- 「後で直す」からハードコード値を許可すること
- ブロッキングゲートが失敗しているのに先に進むこと

## Config

```yaml
# 品質ゲート
quality_gate_path: ".claude/skills/rapid-build/QUALITY_GATE.md"
adapter_path: "{project_root}/rapid-build-adapter.md"  # プロジェクト固有の品質ルール

# 実行モード判定閾値
parallel_threshold_tasks: 3       # 並列可能タスクがこれ以上でマルチエージェント
parallel_threshold_dirs: 2        # ユニークディレクトリがこれ以上でマルチエージェント
max_team_size: 4                  # マルチエージェント最大チームサイズ

# 品質ゲート
max_quality_retries: 3            # 品質ゲート失敗の最大リトライ回数
```

## セキュリティ

- **APIキー/トークン**: 不要（設計書の実装のみ。外部APIは設計書のセキュリティ要件に従う）
- **ログ出力禁止**: ハードコード値スキャンで検出されたシークレットを出力しない
- **PII取り扱い**: 設計書のセキュリティセクションに従う
- **外部アクセス**: なし（ローカル実行のみ）

## 汎用性（Portability）

このスキルは **汎用フレームワーク** — ベースラインコード再利用・Config-First強制・品質ゲート・セキュリティ監査のパターンはプロジェクト非依存。
他社は以下を変更するだけで使える:
1. アダプタファイル（`rapid-build-adapter.md`）で品質ゲート項目をカスタマイズ
2. `QUALITY_GATE.md` を自社の品質基準に差し替え
3. super-planのPLAN_TEMPLATE.md形式の設計書を入力として使用

設計原則（12-Factor App, Shift-Left Security, Unix再利用, SOLID）は業界標準。企業名ハードコードなし。

> lessons/ ディレクトリで leak-learner (L5) と間接接続。直接CALLではない。

| スキル | 関係 | 説明 |
|--------|------|------|
