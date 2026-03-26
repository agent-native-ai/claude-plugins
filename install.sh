#!/bin/bash
# Agent Native Claude Code Skills Installer (super-plan suite)
# Usage: curl -fsSL https://raw.githubusercontent.com/agent-native-ai/claude-plugins/main/install.sh | bash

set -e

REPO="agent-native-ai/claude-plugins"
BRANCH="main"
DEST="$HOME/.claude/skills"
TMP=$(mktemp -d)

# super-plan に関わるスキルのみ
SKILLS="super-plan rapid-build quality-rules pre-check security-audit auto-test"

echo "📦 Agent Native Skills (super-plan suite) をインストール中..."
echo ""

# ダウンロード
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar xz -C "$TMP"

# スキルをコピー
mkdir -p "$DEST"
count=0
for name in $SKILLS; do
  dir="$TMP/claude-plugins-$BRANCH/plugins/$name/skills/$name"
  if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
    rm -rf "$DEST/$name"
    cp -r "$dir" "$DEST/$name"
    echo "  ✅ $name"
    count=$((count + 1))
  else
    echo "  ⚠️  $name (not found, skipped)"
  fi
done

# クリーンアップ
rm -rf "$TMP"

echo ""
echo "Done! $count skills installed to $DEST"
echo ""
echo "claude を起動して /super-plan を試してください。"
echo ""
echo "更新: 同じコマンドを再実行するだけ。"
