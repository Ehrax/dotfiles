#!/bin/bash

# =============================================================================
# sweep — Interactive disk cleanup for macOS developers
# Usage: sweep [--dry-run] [--help|-h]
# Requires: gum (brew install gum)
# =============================================================================

set -e

PROJECTS_DIR="${SWEEP_PROJECTS_DIR:-$HOME/Projects}"
SCAN_DEPTH="${SWEEP_SCAN_DEPTH:-5}"

# ASCII unit separator — safe delimiter that won't appear in paths or labels
DELIM=$'\x1f'

# =============================================================================
# Helpers
# =============================================================================

human_size() {
    local kb="${1:-0}"
    if (( kb >= 1048576 )); then
        awk -v kb="$kb" 'BEGIN {printf "%.1f GB", kb / 1048576}'
    elif (( kb >= 1024 )); then
        printf "%d MB" $(( kb / 1024 ))
    else
        printf "%d KB" "$kb"
    fi
}

dir_size_kb() {
    if [[ -d "$1" ]]; then
        local result
        result=$(du -sk "$1" 2>/dev/null)
        echo "${result%%$'\t'*}"
    else
        echo 0
    fi
}

record_item() {
    local size="${1:-0}" preselect="$2" category="$3" label="$4" path="$5" type="${6:-dir}"
    # Sanitize: strip any unit-separator characters from label and path
    label="${label//$DELIM/}"
    path="${path//$DELIM/}"
    if (( size > 0 )); then
        printf '%s\n' "${size}${DELIM}${preselect}${DELIM}${category}${DELIM}${label}${DELIM}${path}${DELIM}${type}" >> "$RESULTS_FILE"
    fi
}

project_label() {
    local stripped="${1#"$PROJECTS_DIR/"}"
    echo "${stripped}" | cut -d/ -f1-2
}

# =============================================================================
# Scan
# =============================================================================

scan() {
    # ── Dev Artifacts (scanned under ~/Projects) ─────────────────────────
    if [[ -d "$PROJECTS_DIR" ]]; then
        while IFS= read -r -d '' d; do
            local name s parent p
            name=$(basename "$d")
            case "$name" in
                node_modules)
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" "node_modules ($(project_label "$d"))" "$d"
                    ;;
                target)
                    parent=$(dirname "$d")
                    [[ -f "$parent/Cargo.toml" ]] || [[ -f "$parent/Cargo.lock" ]] || continue
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" "target/ ($(project_label "$d"))" "$d"
                    ;;
                .dart_tool)
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" ".dart_tool ($(project_label "$d"))" "$d"
                    ;;
                Pods)
                    p=$(dirname "$d")
                    [[ -f "$p/Podfile" ]] || [[ -f "$(dirname "$p")/Podfile" ]] || continue
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" "Pods ($(project_label "$d"))" "$d"
                    ;;
                .gradle)
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" ".gradle ($(project_label "$d"))" "$d"
                    ;;
            esac
        done < <(find "$PROJECTS_DIR" -maxdepth "$SCAN_DEPTH" -type d \
            \( -name "node_modules" -o -name "target" -o -name ".dart_tool" \
               -o -name "Pods" -o -name ".gradle" \) -prune -print0 2>/dev/null)

        # Path-based patterns (android/build, android/app/build, ios/build)
        while IFS= read -r -d '' d; do
            local s label_prefix
            case "$d" in
                */android/app/build) label_prefix="android/app/build" ;;
                */android/build)     label_prefix="android/build" ;;
                */ios/build)         label_prefix="ios/build" ;;
                *) continue ;;
            esac
            s=$(dir_size_kb "$d")
            record_item "$s" "yes" "Dev" "$label_prefix ($(project_label "$d"))" "$d"
        done < <(find "$PROJECTS_DIR" -maxdepth "$SCAN_DEPTH" -type d \
            \( -path "*/android/app/build" -o -path "*/android/build" -o -path "*/ios/build" \) \
            -prune -print0 2>/dev/null)
    fi

    # ── Tool Caches / IDE / System ───────────────────────────────────────
    local brew_cache
    brew_cache=$(brew --cache 2>/dev/null || echo "$HOME/Library/Caches/Homebrew")

    local specs=(
        # Tool Caches
        "yes|Cache|Homebrew|$brew_cache"
        "yes|Cache|npm|$HOME/.npm/_cacache"
        "yes|Cache|Bun|$HOME/.bun/install/cache"
        "yes|Cache|yarn|$HOME/.yarn/cache"
        "yes|Cache|pnpm store|$HOME/Library/pnpm/store"
        "yes|Cache|Dart pub|$HOME/.pub-cache"
        "yes|Cache|Cargo registry|$HOME/.cargo/registry"
        "no|Cache|CocoaPods repos|$HOME/.cocoapods/repos"
        "yes|Cache|Gradle global|$HOME/.gradle/caches"
        "yes|Cache|pip|$HOME/Library/Caches/pip"
        "no|Cache|FVM Flutter versions|$HOME/.fvm/versions"
        "no|Cache|fnm Node versions|$HOME/.local/share/fnm/node-versions"
        "no|Cache|rbenv Ruby versions|$HOME/.rbenv/versions"
        # IDE / Platform
        "yes|IDE|Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData"
        "no|IDE|Xcode Archives|$HOME/Library/Developer/Xcode/Archives"
        "no|IDE|Xcode DeviceSupport|$HOME/Library/Developer/Xcode/iOS DeviceSupport"
        "yes|IDE|CoreSimulator Caches|$HOME/Library/Developer/CoreSimulator/Caches"
        "yes|IDE|Android build cache|$HOME/.android/build-cache"
        # System
        "no|System|User caches ~/Library/Caches|$HOME/Library/Caches"
        "yes|System|User logs|$HOME/Library/Logs"
        "no|System|Trash|$HOME/.Trash"
    )
    local presel cat label path s
    for spec in "${specs[@]}"; do
        IFS='|' read -r presel cat label path <<< "$spec"
        s=$(dir_size_kb "$path")
        record_item "$s" "$presel" "$cat" "$label" "$path"
    done

    # Docker (only if daemon is running)
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local reclaimable_kb=0
        local raw_line
        while IFS= read -r raw_line; do
            if [[ "$raw_line" =~ ([0-9.]+)GB ]]; then
                reclaimable_kb=$(awk -v val="${BASH_REMATCH[1]}" -v cur="$reclaimable_kb" 'BEGIN {printf "%d", cur + val * 1048576}')
            elif [[ "$raw_line" =~ ([0-9.]+)MB ]]; then
                reclaimable_kb=$(awk -v val="${BASH_REMATCH[1]}" -v cur="$reclaimable_kb" 'BEGIN {printf "%d", cur + val * 1024}')
            elif [[ "$raw_line" =~ ([0-9.]+)kB ]]; then
                reclaimable_kb=$(awk -v val="${BASH_REMATCH[1]}" -v cur="$reclaimable_kb" 'BEGIN {printf "%d", cur + val * 1000 / 1024}')
            fi
        done < <(docker system df --format '{{.Reclaimable}}' 2>/dev/null)
        record_item "$reclaimable_kb" "no" "System" "Docker system prune" "DOCKER_PRUNE" "docker"
    fi
}

# =============================================================================
# Internal scan mode (called by gum spin via self-invocation)
# =============================================================================

if [[ "${1:-}" == "--scan" ]]; then
    if [[ -z "${2:-}" || ! -f "$2" ]]; then
        echo "Error: --scan requires an existing results file path" >&2
        exit 1
    fi
    RESULTS_FILE="$2"
    scan
    exit 0
fi

# =============================================================================
# Main
# =============================================================================

DRY_RUN=false

case "${1:-}" in
    --dry-run) DRY_RUN=true ;;
    --help|-h)
        echo "sweep — Interactive disk cleanup for macOS developers"
        echo ""
        echo "Usage: sweep [--dry-run] [--help|-h]"
        echo ""
        echo "Options:"
        echo "  --dry-run   Show what would be deleted without deleting"
        echo "  --help      Show this help message"
        exit 0
        ;;
esac

if ! command -v gum >/dev/null 2>&1; then
    echo "Error: gum is required. Install with: brew install gum"
    exit 1
fi

RESULTS_FILE=$(mktemp)
trap 'rm -f "$RESULTS_FILE"' EXIT

# Header
echo ""
local_suffix=""; $DRY_RUN && local_suffix=" [DRY RUN]"
gum style --foreground 212 --bold "  sweep — disk cleanup${local_suffix}"
echo ""

# Scan with spinner
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
if ! gum spin --spinner dot --title "Scanning for cleanup targets..." -- bash "$SCRIPT_PATH" --scan "$RESULTS_FILE"; then
    echo "Error: scan phase failed." >&2
    exit 1
fi

# Read results into arrays
SIZES=()
PATHS=()
TYPES=()
DISPLAY=()
PRESELECTED=()
i=0

while IFS="$DELIM" read -r size presel cat label path type; do
    SIZES[$i]=$size
    PATHS[$i]=$path
    TYPES[$i]=$type
    DISPLAY[$i]="$(printf '%3d' "$i"). [${cat}] ${label} ($(human_size "$size"))"
    [[ "$presel" == "yes" ]] && PRESELECTED+=("${DISPLAY[$i]}")
    (( ++i ))
done < "$RESULTS_FILE"

if (( i == 0 )); then
    gum style --foreground 2 "Nothing to clean! Your system is already spotless."
    exit 0
fi

gum style --faint "Found $i items. Space to toggle, Enter to confirm."
echo ""

# Build --selected as repeated flags (safe with any characters in labels)
selected_args=()
for item in "${PRESELECTED[@]}"; do
    selected_args+=(--selected "$item")
done

# Present chooser
SELECTED=$(printf '%s\n' "${DISPLAY[@]}" | gum choose --no-limit --height 25 "${selected_args[@]}") || true

if [[ -z "$SELECTED" ]]; then
    echo ""
    echo "Nothing selected. Bye!"
    exit 0
fi

# Map selected display strings back to indices
TOTAL_KB=0
DELETE_INDICES=()
while IFS= read -r line; do
    for (( j=0; j<i; j++ )); do
        if [[ "${DISPLAY[$j]}" == "$line" ]]; then
            DELETE_INDICES+=("$j")
            TOTAL_KB=$(( TOTAL_KB + SIZES[j] ))
            break
        fi
    done
done <<< "$SELECTED"

echo ""
gum style --foreground 212 --bold "Total: $(human_size "$TOTAL_KB")"

# Show what will be deleted
echo ""
for idx in "${DELETE_INDICES[@]}"; do
    echo "  ${DISPLAY[$idx]}"
    [[ "${TYPES[$idx]}" != "docker" ]] && gum style --faint "    ${PATHS[$idx]}"
done

# Dry run: stop here
if $DRY_RUN; then
    echo ""
    gum style --foreground 3 --bold "[DRY RUN] No files were deleted."
    echo ""
    exit 0
fi

# Confirm
echo ""
if ! gum confirm "Delete $(human_size "$TOTAL_KB")?"; then
    echo "Cancelled."
    exit 0
fi

# Delete
echo ""
FREED_KB=0
FAIL_COUNT=0
for idx in "${DELETE_INDICES[@]}"; do
    path="${PATHS[$idx]}"
    type="${TYPES[$idx]}"

    # Safety: refuse to delete empty, root, or home paths
    if [[ -z "$path" || "$path" == "/" || "$path" == "$HOME" || "$path" == "$HOME/" ]]; then
        gum style --foreground 1 "  ✗ Refused unsafe path: '$path'"
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        continue
    fi

    # Non-docker paths must resolve to somewhere under $HOME
    if [[ "$type" != "docker" ]]; then
        if ! local_realpath=$(realpath "$path" 2>/dev/null); then
            gum style --foreground 1 "  ✗ Could not resolve path (skipped): '$path'"
            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
            continue
        fi
        case "$local_realpath" in
            "$HOME"/*)
                # OK — path is under $HOME
                ;;
            *)
                gum style --foreground 1 "  ✗ Refused path outside \$HOME: '$path'"
                FAIL_COUNT=$(( FAIL_COUNT + 1 ))
                continue
                ;;
        esac
    fi

    if [[ "$type" == "docker" ]]; then
        gum style --faint "  Deleting Docker cache..."
        if docker system prune -f >/dev/null 2>&1; then
            gum style --foreground 2 "  ✓ Docker system prune"
            FREED_KB=$(( FREED_KB + SIZES[idx] ))
        else
            gum style --foreground 1 "  ✗ Docker system prune failed"
            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        fi
    else
        gum style --faint "  Cleaning $(basename "$path")..."
        local before_kb
        before_kb=$(dir_size_kb "$path")

        # Delete contents (not the directory itself) so parent dirs like
        # ~/Library/Caches survive.  Protected children are silently skipped.
        find "$path" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
            | xargs -0 rm -rf 2>/dev/null || true

        local after_kb actually_freed
        after_kb=$(dir_size_kb "$path")
        actually_freed=$(( before_kb - after_kb ))

        if (( actually_freed > 0 )); then
            gum style --foreground 2 "  ✓ ${DISPLAY[$idx]} — freed $(human_size "$actually_freed")"
            FREED_KB=$(( FREED_KB + actually_freed ))
        else
            gum style --foreground 3 "  ~ ${DISPLAY[$idx]} — nothing removable (protected)"
            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        fi
    fi
done

echo ""
if (( FAIL_COUNT > 0 )); then
    gum style --foreground 3 --bold "  Freed ~$(human_size "$FREED_KB") ($FAIL_COUNT items failed)"
else
    gum style --foreground 2 --bold "  Freed $(human_size "$FREED_KB")!"
fi
echo ""
