#!/bin/bash

# =============================================================================
# update-superpowers — Sync skills from obra/superpowers into configs/agents/skills
# Downloads only the skills/ directory via tarball (no .git)
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/configs/agents/skills"
TMP_DIR="$(mktemp -d)"
REPO="obra/superpowers"
BRANCH="main"
MARKER="$SKILLS_DIR/.superpowers-upstream-commit"

# Skills that are ours (not from superpowers) — skip these during sync
LOCAL_ONLY=(
    agent-browser
    commit
    find-skills
    gh
    gh-pr
    gl-pr
    glab
    prompt-engineering-patterns
    simplify-local
    skill-creator
)

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "Fetching latest skills from $REPO..."
curl -sL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" \
    | tar xz -C "$TMP_DIR" --strip-components=2 "superpowers-$BRANCH/skills"

if [ ! -d "$TMP_DIR" ] || [ -z "$(ls -A "$TMP_DIR")" ]; then
    echo "Error: failed to download skills"
    exit 1
fi

echo "Syncing skills to $SKILLS_DIR..."
for skill_dir in "$TMP_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"

    # Skip local-only skills
    skip=false
    for local in "${LOCAL_ONLY[@]}"; do
        if [ "$skill_name" = "$local" ]; then
            skip=true
            break
        fi
    done
    if $skip; then
        continue
    fi

    # Remove old version and copy new
    rm -rf "${SKILLS_DIR:?}/$skill_name"
    cp -R "$skill_dir" "$SKILLS_DIR/$skill_name"
    echo "  ✓ $skill_name"
done

# Record upstream commit for tracking
UPSTREAM_COMMIT="$(curl -s "https://api.github.com/repos/$REPO/commits/$BRANCH" | grep -m1 '"sha"' | cut -d'"' -f4)"
echo "$UPSTREAM_COMMIT" > "$MARKER"

echo ""
echo "Done. Superpowers skills synced to commit ${UPSTREAM_COMMIT:0:7}"
