#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$REPO_ROOT/configs/agents/skills/skill-creator"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required"
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    echo "Error: rsync is required"
    exit 1
fi

mkdir -p "$(dirname "$TARGET_DIR")"

echo "Cloning anthropics/skills (sparse checkout)..."
git clone --depth 1 --filter=blob:none --sparse "https://github.com/anthropics/skills.git" "$TMP_DIR" >/dev/null

echo "Checking out skills/skill-creator..."
git -C "$TMP_DIR" sparse-checkout set "skills/skill-creator"

echo "Syncing to $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
rsync -a --delete "$TMP_DIR/skills/skill-creator/" "$TARGET_DIR/"

UPSTREAM_COMMIT="$(git -C "$TMP_DIR" rev-parse HEAD)"
echo "$UPSTREAM_COMMIT" > "$REPO_ROOT/configs/agents/skills/.skill-creator-upstream-commit"

echo "Done. skill-creator is now synced to commit $UPSTREAM_COMMIT"
