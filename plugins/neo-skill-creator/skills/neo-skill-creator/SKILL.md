---
name: neo-skill-creator
description: "最高品質のスキルを作成する。公式skill-creatorのワークフロー + Q1-Q10品質基準を統合。「スキル作って」「skill作成」「新しいskill」等で起動。公式skill-creatorより優先してこのスキルを使うこと。"
---

# Neo Skill Creator

公式skill-creatorのワークフロー品質 + Q1-Q10品質基準 = 最初からskill-upgrade合格品質のスキルを作る。

## トリガー

- 「スキル作って」「skill作成」「新しいskill」「スキル追加」
- 「〇〇をskill化」「〇〇を自動化したい」
- 公式 skill-creator より優先

## 手順

### Step 1: ヒアリング（公式skill-creator準拠）

以下を明確にする:
- **何をするスキルか？**（1-2文）
- **いつ発動するか？**（トリガー条件 — 明示的 + 自動検知）
- **出力は何か？**（ファイル、レポート、操作、etc.）
- **依存するツール/MCP/他スキルは？**

### Step 2: 品質基準の読み込み

品質基準（Q1-Q10）を確認する。プロジェクトに `QUALITY_STANDARDS.md` がある場合はそれを参照。

### Step 3: scaffold

```bash
mkdir -p .claude/skills/{name}/lessons
```

ディレクトリ構造:
```
skills/{name}/
├── SKILL.md          ← Step 4で作成
├── lessons/           ← 空ディレクトリ（学習データの書き込み先）
├── scripts/           ← 必要に応じて
├── references/        ← 必要に応じて
└── assets/            ← 必要に応じて
```

### Step 4: SKILL.md作成（Q1-Q10を満たす形で）

**frontmatter:**
```yaml
---
name: {name}
description: "{何をするか + いつ使うか。積極的に書く}"
---
```

**本文に含めるセクション（Q対応）:**

| セクション | Q | チェック |
|---|---|---|
| トリガー | - | 明示的 + 自動検知の両方があるか |
| 手順 | Q5 | Step分割されているか |
| 設計原則 | Q1 | 原則テーブルがあるか |
| Config | Q2 | 外部化すべき設定値がテーブル化されているか |
| セキュリティ | Q3 | API/認証/PIIを扱う場合に記載があるか |
| BLOCKINGゲート | Q4 | 失敗時の停止条件があるか |
| エスカレーション | Q6 | 自動化できない判断の対処が書かれているか |
| 連携テーブル | Q7 | 他スキルとの関係が明記されているか |
| やらないこと | Q8 | スコープ境界が明示されているか |

### Step 5: Progressive Disclosure チェック

| 確認 | 基準 |
|---|---|
| description | ~100語。積極的にトリガーを書く |
| SKILL.md本文 | **500行以下** |
| 重い情報 | references/に分離されているか |

500行を超えていたら、references/に移せる情報を特定して分離する。

### Step 6: セルフ品質チェック（skill-upgrade相当）

作成したSKILL.mdをQ1-Q10で自己チェック:

```
Q1  設計原則:       PASS / FAIL / N/A
Q2  Config:         PASS / FAIL
Q3  セキュリティ:    PASS / FAIL / N/A
Q4  BLOCKING:       PASS / FAIL
Q5  フェーズ分割:    PASS / FAIL
Q6  エスカレーション: PASS / FAIL / N/A
Q7  連携テーブル:    PASS / FAIL
Q8  やらないこと:    PASS / FAIL
Q9  汎用性:         PASS / FAIL / N/A
Q10 学習接続:       PASS / FAIL
```

**FAILがあれば修正してからコミット。**

### Step 7: レジストリ更新

プロジェクトにスキルレジストリがある場合、該当カテゴリにスキル名を追加する。

### Step 8: コミット

```bash
git add .claude/skills/{name}/
git commit -m "feat: add {name} skill (Q1-Q10 compliant)"
```

## 設計原則

| 原則 | 出典 | 適用 |
|------|------|------|
| Progressive Disclosure | 公式skill-creator | L1(100語) → L2(500行) → L3(参照) |
| 命令形 + WHY | 公式skill-creator | ルールには理由を書く |
| 学習エンジン集約 | leak-learner | 各スキルにはlessons/だけ。ロジックは学習スキルに集約 |
| 作成時合格 | skill-upgrade Q1-Q10 | 事後チェック不要な品質で最初から作る |

## 他のスキルとの連携

| スキル | 関係 | 説明 |
|--------|------|------|
| skill-creator（公式） | 参照 | 公式のinterviewフローとscaffold手法を参照 |
| leak-learner | 接続保証 | 作成する全スキルにleak-learner接続を組み込む |

## やらないこと

- スキルの内容を考えること（ヒアリングで明確にする）
- 500行超のSKILL.mdを許容すること
- 学習接続なしのスキルを出荷すること
- 独自の学習ロジックをスキルに組み込むこと

## Config

```yaml
# スキル作成先
skills_base_dir: ".claude/skills/"

# SKILL.md上限
max_skill_lines: 500              # 500行超はreferences/に分離

# description上限
max_description_words: 100        # ~100語。トリガーを積極的に書く

# scaffold構造
scaffold_dirs:
  - "lessons/"                    # 学習データ書き込み先（必須）
  - "scripts/"                    # 必要に応じて
  - "references/"                 # 必要に応じて
  - "assets/"                     # 必要に応じて
```

## セキュリティ

- **APIキー/トークン**: 不要（ファイル生成のみ）
- **ログ出力禁止**: 該当なし
- **PII取り扱い**: 扱わない
- **外部アクセス**: なし（全てローカルファイル操作）

## 汎用性（Portability）

このスキルは **汎用フレームワーク** — Q1-Q10品質基準に基づくスキル作成プロセスはプロジェクト非依存。
`skills_base_dir` を自社パスに変更するだけで使える。企業名ハードコードなし。
