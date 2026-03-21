# Skill: presentation-architect

- **description**: 会社説明資料・提案書・ピッチデッキを一発で高品質に生成するオーケストレーター。ブランド未定義でもOK — プロファイルがなければ自動でブランド設計（MVV・カラー・フォント）から始める
- **type**: user
- **trigger**: 「資料作って」「スライド作って」「デッキ作って」「提案書作成」「会社説明資料」「ピッチ作って」「presentation」「deck」
- **does NOT trigger**: バグ修正、バックエンド実装、ドキュメント更新（スライド以外）

---

## 設計原則

| 原則 | 出典 | 適用 |
|------|------|------|
| SSOT参照ファースト | 12-Factor App | 色・フォント・MVVは全てSSOTから読む。ハードコード禁止 |
| 再利用 > 再発明 | Unix哲学 | ベースデッキテンプレート（`{profile.templates.base_deck}`）をコピー。ゼロから書かない |
| 失敗パターン回避 | 過去セッション教訓 | 蓄積された教訓を事前適用して手戻りゼロ |
| 図解メソッド分離 | — | テキスト図=HTML/CSS/SVG、雰囲気=AI画像。混ぜない |
| BLOCKINGゲート | rapid-build | Phase 0(SSOT読み込み)とPhase 4(品質チェック)を通過しないと進めない |

## Config

```yaml
# プロファイル（企業固有の設定は全てここから読む）
active_profile: "profiles/default.yaml"  # 変更するだけで他社に切替

# スキル内部パス（企業非依存）
lessons_universal: ".claude/skills/presentation-architect/SLIDE_DESIGN_LESSONS.md"  # 汎用ルール
# 企業固有lessons → profile.paths.lessons（profiles/lessons/{company}.md）
quality_gate: ".claude/skills/presentation-architect/QUALITY_GATE.md"

# 閾値（企業非依存のデザイン基準）
min_font_size: 18            # px。プレゼン最小フォント
min_heading_size: 32         # px。見出し最小
min_geo_text_line_height: 1.1  # gのディセンダー切れ防止
min_stat_number_size: 48     # px。データビジュアライゼーション風数字の最小
watermark_patch_size: 150    # px。AI画像ウォーターマーク除去範囲
canvas_crop_percent: 5       # %。キャンバス縁トリミング
```

> **企業固有の値（MVV、色、パス、アートスタイル等）は `profiles/{company}.yaml` に定義。**
> SKILL.md本文には企業名・ブランド色・MVVテキストをハードコードしない。

---

## 依存スキル

| Dependency | Role |
|------------|------|
| `frontend-slides` | HTML生成エンジン |
| AI画像生成 | 背景/アート（プロンプトを出力、ユーザーが外部で生成） |

## SSOT References

| What | Source |
|------|--------|
| Brand Design System | `{profile.paths.ssot_brand}` |
| MVV | `{profile.paths.ssot_mvv}` |
| Product Philosophy | `{profile.paths.ssot_philosophy}` |
| Universal Lessons | Config `lessons_universal`（汎用ルール） |
| Company Lessons | `{profile.paths.lessons}`（企業固有 — 生の声） |
| Quality Gate | Config `quality_gate` |
| AI Image Prompts | `{profile.paths.ssot_image_prompts}` |
| Base template | `{profile.templates.base_deck}` |

> パスは全て `profiles/{company}.yaml` から読む。SKILL.md本文にハードコードしない。

---

## Workflow（6フェーズ）

### Phase 0: プロファイル + SSOT読み込み（BLOCKING）

**1行もコードを書く前に、以下を全てReadする。省略禁止。**

#### Step 0-A: プロファイル存在チェック

1. Config `active_profile` で指定されたファイルを Read する
2. **ファイルが存在しない** or **`company.name` が空** → **Brand Bootstrap を自動起動**

```
プロファイルなし検知
  → Read "BRAND_BOOTSTRAP.md"
  → Brand Bootstrap Step 1-7 を実行（リファレンスリサーチ → MVV → カラー → フォント → profile.yaml 生成）
  → 生成された profile.yaml を active_profile に設定
  → Step 0-B に進む
```

**ユーザーは「資料作って」と言うだけ。** ブランドが未定義でもスキルが止まらない。必要な上流工程が自動で起動し、全てが揃った状態で資料生成に入る。

詳細: `BRAND_BOOTSTRAP.md`

#### Step 0-B: SSOT読み込み

1. Read `profiles/{company}.yaml`（企業プロファイル）
2. Read `{profile.paths.ssot_brand}`（ブランドデザインシステム — あれば）
3. Read `{profile.paths.ssot_mvv}`（確定済みMVV — あれば）
4. Read `{profile.paths.ssot_philosophy}`（プロダクト思想 — あれば）
5. Read `SLIDE_DESIGN_LESSONS.md`（汎用ルール）
5b. Read `{profile.paths.lessons}`（企業固有の教訓 — あれば。生の声形式）
6. Read `{profile.paths.ssot_image_prompts}`（AI画像生成プロンプト集 — あれば）
7. Read `{profile.templates.base_deck}`（ベーステンプレート — あれば）

**パスが空欄のSSOTはスキップ**（Brand Bootstrapで生成した直後はSSOTファイルがまだ存在しない。プロファイルの情報だけで資料生成を進める）

### Phase 1: 資料タイプ判定

ユーザーの指示からデッキタイプを分類する。

| 指示 | タイプ | ベース |
|------|--------|--------|
| 「会社説明資料」「About us」 | Company Deck | ベースデッキテンプレート（`{profile.templates.base_deck}`）をコピー |
| 「◯◯社向け提案書」「Proposal」 | Proposal | Company Deck + クライアント固有PARTを追加 |
| 「ピッチ」「投資家向け」 | Pitch Deck | 構成変更（Problem → Solution → Market → Team → Ask） |
| 「営業資料」「Sales deck」 | Sales Deck | Proposal の簡略版 |

### Phase 2: 構成設計（4パート構造）

リファレンス企業の構成をベースに、4パート構成で設計する。

```
PART 1: About        -- 表紙, 目次, Founder, 会社情報
PART 2: Purpose & Values -- MVV, Valuesパレット, Value詳細
PART 3: Platform     -- 時代背景, プラットフォーム概要, 事業説明
PART 4: Use Cases    -- 業界特化（差し替え可能）
Ending: ロゴ + Vision + Contact
```

**Pitch Deckの場合**: Problem → Solution → Market → Team → Ask に再構成。

### Phase 3: スライド生成（ルール全適用）

#### 色ルール

| ルール | 詳細 |
|--------|------|
| テキスト色 | 白 or 黒のみ。**赤テキスト禁止。** |
| 暗い背景 | 白テキスト |
| 明るい/暖色背景 | 黒テキスト |
| 赤の使用 | プロファイル指定のValue（`{profile.mvv.values}`）の背景色としてのみ |
| 図解画像 | プライマリカラー禁止。`{profile.brand.depth_color}` / `{profile.brand.accent_color}` / 黒 / 白のみ |

#### フォントルール

| ルール | 詳細 |
|--------|------|
| 最小フォントサイズ | 18px（プロダクトUI用サイズスケールを使わない） |
| 見出し | `clamp(32px, 4vw, 52px)` 以上 |
| geo-text の line-height | 最低 1.1（`g` のディセンダー切れ防止） |
| Sourceラベル | 14px のみ例外 |

#### 図解メソッド選択

| 用途 | メソッド | 理由 |
|------|----------|------|
| 背景、テクスチャ、アート | AI画像生成 | 抽象表現・ムード |
| データ、数字、比較 | HTML/CSS/SVG | テキスト精度・レイアウト精密 |
| フロー図、構造図（ラベル付き） | HTML/CSS/SVG | ラベル・矢印 → コードが正確 |
| ポートレート、アート | AI画像生成 | リアル/抽象 |

#### テキストルール

| ルール | 詳細 |
|--------|------|
| 文体 | 「宣言する、説明しない」（宣言型スタイル） |
| 会社説明資料にクライアントデータ | 禁止。会社デッキは会社情報のみ |
| 数量の表現 | 具体的な数字より抽象的表現を優先（プロファイルのMVVトーンに合わせる） |

#### レイアウトルール

| ルール | 詳細 |
|--------|------|
| セクション仕切り | マットホワイト。幾何学パターン禁止（ノイズになる） |
| 表紙と最終ページ | 同じ世界観で呼応（ブックエンド設計） |
| Valuesスライド | `{profile.mvv.values[].color_hex}` のカラーパレット |
| Valueカラーバー | アートワークとテキストをカラーバーで紐づけ |

#### 画像ルール

| ルール | 詳細 |
|--------|------|
| Valuesアートスタイル | プロファイル指定のアートスタイル（`{profile.brand.art_style}`） |
| 図解画像の色 | 黒 / 金 / 藍 / 白のみ。赤禁止 |
| 背景画像 | プロファイル指定のアートスタイルフリーカラー |
| AI画像ウォーターマーク | 生成後に必ずPython/Pillowで除去 |
| キャンバス縁 | 5-10%クロップで隙間を除去 |

#### AI画像プロンプト集の管理（SSOT連動 — 必須）

画像を新規生成・差し替えする場合、以下の手順を**必ず**実行する。

1. **Read**: `{profile.paths.ssot_image_prompts}` を読んで既存プロンプトの品質レベルを確認
2. **Match**: 既存プロンプトの構造に合わせて新規プロンプトを作成。雑なプロンプトをゼロから書かない
3. **Write**: 新規プロンプトをプロンプト集に追記
4. **Commit**: プロンプト集の更新をHTMLの更新と同時にコミット
5. **Verify**: 画像生成後、プロンプト集に記載されたファイル名と実際のassetsフォルダのファイル名が一致することを確認

### Phase 4: 品質ゲート（BLOCKING）

`QUALITY_GATE.md` の全チェック項目を実行する。
**1つでもFAILなら修正してからPhase 5に進む。**

### Phase 5: ユーザー確認 → push

1. ブラウザで開いてユーザー確認
2. **ユーザー承認後のみpush**
3. 論理的な変更単位ごとに即commit

---

## Anti-Pattern Registry

蓄積された意思決定 + 修正パターン。
詳細は `SLIDE_DESIGN_LESSONS.md` に記載。以下はカテゴリ別サマリ。

### 色アンチパターン
- **C1**: 赤テキスト → 赤は背景/アクセントのみ
- **C2**: 図解に赤 → 黒 / 金 / 藍 / 白のみ
- **C3**: 色使いすぎ → モノクロベース + 1アクセント
- **C4**: Valuesアートがフォトリアル → プロファイル指定のアートスタイル抽象表現主義

### フォントアンチパターン
- **F1**: 18px未満テキスト → プレゼン最小は18px
- **F2**: line-height 0.95以下 → 最低1.1
- **F3**: プロダクトUIサイズスケール流用 → プレゼン専用スケール

### 図解アンチパターン
- **D1**: AI生成のテキスト入り図 → テキスト図はHTML/CSS/SVG
- **D2**: 生のSVGフローチャート → 「情報を描く」ではなく「情報をデザインする」
- **D3**: データスライドの数字が小さい → 48px以上
- **D4**: 図とテキストの色が不一致 → カラーバーで紐づけ

### テキストアンチパターン
- **T1**: 説明的コピー → 宣言的ステートメント
- **T2**: 会社デッキにクライアントデータ → 会社デッキは会社情報のみ
- **T3**: 固有の数字表現 → プロファイルのMVVに合わせた表現

### レイアウトアンチパターン
- **L1**: 幾何学パターンの仕切り → マットホワイト仕切り
- **L2**: 表紙/エンディングのビジュアル不一致 → 同じ世界観のブックエンド
- **L3**: テキストがスライド高さを超える → コンテンツを収める

### 画像アンチパターン
- **I1**: AI画像ウォーターマーク残存 → Pillow除去
- **I2**: キャンバス縁の隙間 → 5-10%クロップ
- **I3**: ポートレート表紙の隙間 → background-size:coverの隙間をクロップ

### ワークフローアンチパターン
- **W1**: ユーザー承認前にpush → 承認後のみpush
- **W2**: コミット遅延 → 即commit
- **W3**: 受領画像を未処理 → 分析 → マッピング → 移動 → ウォーターマーク除去 → クロップ → 配置 → commit
- **W4**: SSOT更新後に伝播忘れ → SSOT変更時は全参照先を更新

---

## セキュリティ

- **APIキー/トークン**: 不要（HTML生成のみ。AI画像生成はユーザーが外部ツールで実行）
- **ログ出力禁止**: クライアント固有データ（社名・KPI・価格）をスライドにハードコードしない
- **PII取り扱い**: 扱わない。提案書テンプレートにはプレースホルダーのみ
- **外部アクセス**: なし（全てローカルファイル操作）

---

## エスカレーション

自動化で完了できない場合:

| 状況 | ユーザーに伝えること | ユーザーの操作 | 再開方法 |
|------|-------------------|-------------|---------|
| SSOTファイルが見つからない | 「{ファイル名}が見つかりません。パスを教えてください」 | 正しいパスを指示 | Phase 0を再実行 |
| AI画像が必要 | 「以下のプロンプトで画像を生成してください」+ プロンプト一覧 | AI画像生成ツールで生成しダウンロード | 「ダウンロードした」と言えば画像処理フロー開始 |
| 品質ゲートFAIL | 「Q{番号}がFAILです。{具体的な問題}」 | 修正方針を指示 or 「直して」 | 該当箇所を修正しPhase 4を再実行 |
| 資料タイプが曖昧 | 「会社説明資料と提案書のどちらですか？」 | タイプを指示 | Phase 1から再実行 |
| MVVが変更されている | 「MVVが前回と異なります。最新版で進めますか？」 | 確認 | 最新MVVでPhase 2から再実行 |

---

## 他のスキルとの連携

| スキル | 関係 | 説明 |
|--------|------|------|
| `frontend-slides` | 出力先 | HTML生成エンジン。Phase 3のスライド実装を委譲 |
| `BRAND_BOOTSTRAP.md` | 内蔵 | プロファイル不在時にPhase 0から自動起動。MVV・カラー・フォント・リファレンスリサーチを実行しprofile.yaml生成 |
| `super-plan` | 入力元 | 資料の構成が複雑な場合、先にsuper-planで設計書を作る |
| `rapid-build` | 並列 | 大量スライド生成時にmulti-agentで並列実行 |
| `leak-learner` | 学習 | ユーザー指摘をlessons/に記録。2+スキル共通パターンはGlobal rulesに昇格 |

---

## このスキルがやらないこと

- **PPT/Keynoteへの変換** — それは `frontend-slides` のPhase 4
- **AI画像の生成自体** — プロンプトは出すが、生成はユーザーが外部ツールで実行
- **既存ブランドデザインシステムの定義変更** — SSOTの責務。ただし未定義の場合はBRAND_BOOTSTRAPで新規策定する
- **既存MVV・プロダクト思想の変更** — SSOTの責務。ただし未定義の場合はBRAND_BOOTSTRAPで新規策定する
- **クライアント固有の提案内容の判断** — ユーザーがスコープを指示する

---

## 汎用性（Portability）

このスキルは **フレームワーク（汎用）+ プロファイル（企業固有）** の構造。
他社は `profiles/_template.yaml` をコピーして自社用に埋めるだけで使える。

### ファイル構成

```
presentation-architect/
├── SKILL.md                  ← フレームワーク（企業名ゼロ）
├── BRAND_BOOTSTRAP.md        ← 自動ブランド設計（プロファイル不在時に起動）
├── SLIDE_DESIGN_LESSONS.md   ← デザイン教訓（汎用）
├── QUALITY_GATE.md           ← 品質基準（汎用）
└── profiles/
    └── _template.yaml        ← 手動設定用テンプレート（Brand Bootstrapがあれば不要）
```

### 他社の導入手順（自動パイプライン）

1. Claude Code をインストール
2. presentation-architect スキルをコピー
3. 「資料作って」と言う
4. → **プロファイル不在を自動検知** → Brand Bootstrap が起動
5. → 3問のヒアリング → リファレンス企業リサーチ → MVV策定 → カラーパレット → フォント → アートスタイル
6. → `profiles/{company}.yaml` を自動生成
7. → 資料生成に自動移行

**手動でプロファイルを埋める必要はない。** 「資料作って」の一言で、ブランド設計から資料完成まで一気通貫。

### プロファイルで外部化されている企業固有の値

| 値 | プロファイルのキー |
|----|-----------------|
| 会社名 | `company.name` |
| MVV全文 | `mvv.*` |
| ブランドカラー | `brand.primary_color`, `brand.accent_color` 等 |
| アートスタイル | `brand.art_style` |
| フォント | `brand.font_*` |
| SSOTファイルパス | `paths.*` |
| ベーステンプレート | `templates.base_deck` |
| Values色マッピング | `mvv.values[].color_token` |
