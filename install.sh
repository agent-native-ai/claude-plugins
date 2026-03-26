#!/bin/bash
# Agent Native Claude Code Skills Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/agent-native-ai/claude-plugins/main/install.sh | bash

set -e

REPO="agent-native-ai/claude-plugins"
BRANCH="main"
DEST="$HOME/.claude/skills"
TMP=$(mktemp -d)

# 全11スキル（コア6 + セキュリティ連携5）
SKILLS="super-plan rapid-build quality-rules pre-check security-audit auto-test audit-context-building insecure-defaults sharp-edges semgrep codeql"

echo "📦 Agent Native Skills をインストール中..."
echo ""
echo "── Core Skills ──"

curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar xz -C "$TMP"

mkdir -p "$DEST"
core_count=0
sec_count=0

for name in super-plan rapid-build quality-rules pre-check security-audit auto-test; do
  dir="$TMP/claude-plugins-$BRANCH/plugins/$name/skills/$name"
  if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
    rm -rf "$DEST/$name"
    cp -r "$dir" "$DEST/$name"
    echo "  ✅ $name"
    core_count=$((core_count + 1))
  fi
done

echo ""
echo "── Security Extension Skills ──"

for name in audit-context-building insecure-defaults sharp-edges semgrep codeql; do
  dir="$TMP/claude-plugins-$BRANCH/plugins/$name/skills/$name"
  if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
    rm -rf "$DEST/$name"
    cp -r "$dir" "$DEST/$name"
    echo "  ✅ $name"
    sec_count=$((sec_count + 1))
  fi
done

rm -rf "$TMP"

total=$((core_count + sec_count))
echo ""
echo "Done! $total skills installed ($core_count core + $sec_count security)"
echo ""
echo "claude を起動して /super-plan を試してください。"
echo ""
echo "更新: 同じコマンドを再実行するだけ。"
