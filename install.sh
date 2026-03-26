#!/bin/bash
# Agent Native Claude Code Skills Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/agent-native-ai/claude-plugins/main/install.sh | bash

set -e

REPO="agent-native-ai/claude-plugins"
BRANCH="main"
DEST="$HOME/.claude/skills"
TMP=$(mktemp -d)

echo "📦 Agent Native Skills をインストール中..."
echo ""

# ダウンロード
curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar xz -C "$TMP"

# スキルをコピー
mkdir -p "$DEST"
count=0
for dir in "$TMP"/claude-plugins-$BRANCH/plugins/*/skills/*/; do
  name=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] || continue
  rm -rf "$DEST/$name"
  cp -r "$dir" "$DEST/$name"
  echo "  ✅ $name"
  count=$((count + 1))
done

# クリーンアップ
rm -rf "$TMP"

echo ""
echo "Done! $count skills installed to $DEST"
echo ""
echo "claude を起動して /super-plan を試してください。"
echo ""
echo "更新: 同じコマンドを再実行するだけ。"
