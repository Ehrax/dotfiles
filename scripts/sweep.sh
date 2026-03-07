#!/bin/bash

# =============================================================================
# sweep — Interactive disk cleanup for macOS developers
# Usage: sweep [--dry-run] [--discover] [--allow-system] [--preset <name>] [--help|-h]
# Requires: gum (brew install gum)
# =============================================================================

set -e

PROJECTS_DIR="${SWEEP_PROJECTS_DIR:-$HOME/Projects}"
SCAN_DEPTH="${SWEEP_SCAN_DEPTH:-5}"
DISCOVER_TOP_N="${SWEEP_DISCOVER_TOP_N:-8}"
DISCOVER_MIN_KB="${SWEEP_DISCOVER_MIN_KB:-524288}"
DISCOVER_DEPTH="${SWEEP_DISCOVER_DEPTH:-3}"
DISCOVER_ROOTS="${SWEEP_DISCOVER_ROOTS:-$PROJECTS_DIR|$HOME/Downloads|$HOME/Library/Developer|$HOME/Library/Caches|$HOME/.cache}"
INCLUDE_VENV="${SWEEP_INCLUDE_VENV:-false}"

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

dir_size_kb_sudo() {
    if [[ -d "$1" ]]; then
        local result
        result=$(sudo du -sk "$1" 2>/dev/null || true)
        echo "${result%%$'\t'*}"
    else
        echo 0
    fi
}

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

validate_preset() {
    case "$1" in
        safe|balanced|aggressive) return 0 ;;
        *) return 1 ;;
    esac
}

preset_preselect() {
    local preset="$1" default_preselect="$2" category="$3"
    case "$preset" in
        safe)
            case "$category" in
                Dev|IDE) echo "yes" ;;
                *) echo "no" ;;
            esac
            ;;
        balanced)
            echo "$default_preselect"
            ;;
        aggressive)
            echo "yes"
            ;;
        *)
            echo "$default_preselect"
            ;;
    esac
}

project_label() {
    local stripped="${1#"$PROJECTS_DIR/"}"
    echo "${stripped}" | cut -d/ -f1-2
}

short_path() {
    local p="$1"
    if [[ "$p" == "$HOME"* ]]; then
        printf '~%s' "${p#$HOME}"
    else
        printf '%s' "$p"
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

is_path_recorded() {
    local target="$1"
    [[ -s "$RESULTS_FILE" ]] || return 1
    while IFS="$DELIM" read -r _size _presel _cat _label path _type; do
        [[ "$path" == "$target" ]] && return 0
    done < "$RESULTS_FILE"
    return 1
}

is_system_allowlisted_path() {
    local real="$1"
    case "$real" in
        /Library/Caches|/Library/Caches/*) return 0 ;;
        *) return 1 ;;
    esac
}

brew_cleanup_estimate_kb() {
    local brew_cache
    brew_cache=$(brew --cache 2>/dev/null || echo "$HOME/Library/Caches/Homebrew")
    dir_size_kb "$brew_cache"
}

docker_reclaimable_kb() {
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
    echo "$reclaimable_kb"
}

discover_large_dirs() {
    local scratch_file
    scratch_file=$(mktemp)

    local old_ifs="$IFS"
    IFS='|'
    read -r -a roots <<< "$DISCOVER_ROOTS"
    IFS="$old_ifs"

    local root d s found=0
    for root in "${roots[@]}"; do
        [[ -d "$root" ]] || continue
        while IFS= read -r -d '' d; do
            is_path_recorded "$d" && continue
            s=$(dir_size_kb "$d")
            (( s >= DISCOVER_MIN_KB )) || continue
            printf '%s%s%s\n' "$s" "$DELIM" "$d" >> "$scratch_file"
            found=1
        done < <(find "$root" -mindepth 1 -maxdepth "$DISCOVER_DEPTH" -type d -print0 2>/dev/null)
    done

    if (( found != 1 )); then
        rm -f "$scratch_file"
        return 0
    fi

    local line count=0 size path
    while IFS="$DELIM" read -r size path; do
        [[ -n "$path" ]] || continue
        record_item "$size" "no" "Discover" "Large directory $(short_path "$path")" "$path" "dir"
        count=$(( count + 1 ))
        (( count >= DISCOVER_TOP_N )) && break
    done < <(sort -nr "$scratch_file")

    rm -f "$scratch_file"
}

print_help() {
    echo "sweep — Interactive disk cleanup for macOS developers"
    echo ""
    echo "Usage: sweep [--dry-run] [--discover] [--allow-system] [--preset <name>] [--help|-h]"
    echo ""
    echo "Options:"
    echo "  --dry-run         Show what would be deleted without deleting"
    echo "  --discover        Include discovered large directory candidates"
    echo "  --allow-system    Include system cache target /Library/Caches (sudo required)"
    echo "  --preset <name>   Preselection preset: safe | balanced | aggressive"
    echo "  --help            Show this help message"
    echo ""
    echo "Environment:"
    echo "  SWEEP_PRESET            Default preset (safe|balanced|aggressive)"
    echo "  SWEEP_DISCOVER_TOP_N    Number of discovered items to include (default: 8)"
    echo "  SWEEP_DISCOVER_MIN_KB   Minimum size for discovered items in KB (default: 524288)"
    echo "  SWEEP_DISCOVER_DEPTH    Max depth for discover scanning (default: 3)"
    echo "  SWEEP_DISCOVER_ROOTS    Pipe-separated roots to scan for discover mode"
    echo "  SWEEP_INCLUDE_VENV      Include venv/.venv artifacts in project scan"
}

# =============================================================================
# Scan
# =============================================================================

scan() {
    # ── Dev Artifacts (scanned under PROJECTS_DIR) ───────────────────────
    if [[ -d "$PROJECTS_DIR" ]]; then
        local names=(
            "node_modules"
            "target"
            ".dart_tool"
            "Pods"
            ".gradle"
            ".nuxt"
            ".turbo"
            ".parcel-cache"
            ".svelte-kit"
            ".pytest_cache"
            ".mypy_cache"
            ".ruff_cache"
            ".build"
        )
        if is_true "$INCLUDE_VENV"; then
            names+=("venv" ".venv")
        fi

        local find_expr=()
        local n
        for n in "${names[@]}"; do
            find_expr+=( -name "$n" -o )
        done
        unset "find_expr[$(( ${#find_expr[@]} - 1 ))]"

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
                .build)
                    parent=$(dirname "$d")
                    [[ -f "$parent/Package.swift" ]] || continue
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" ".build ($(project_label "$d"))" "$d"
                    ;;
                venv|.venv)
                    s=$(dir_size_kb "$d")
                    record_item "$s" "no" "Dev" "$name ($(project_label "$d"))" "$d"
                    ;;
                .nuxt|.turbo|.parcel-cache|.svelte-kit|.pytest_cache|.mypy_cache|.ruff_cache)
                    s=$(dir_size_kb "$d")
                    record_item "$s" "yes" "Dev" "$name ($(project_label "$d"))" "$d"
                    ;;
            esac
        done < <(find "$PROJECTS_DIR" -maxdepth "$SCAN_DEPTH" -type d \( "${find_expr[@]}" \) -prune -print0 2>/dev/null)

        # Path-based patterns (.next/cache, android/build, android/app/build, ios/build)
        while IFS= read -r -d '' d; do
            local s label_prefix
            case "$d" in
                */.next/cache)      label_prefix=".next/cache" ;;
                */android/app/build) label_prefix="android/app/build" ;;
                */android/build)     label_prefix="android/build" ;;
                */ios/build)         label_prefix="ios/build" ;;
                *) continue ;;
            esac
            s=$(dir_size_kb "$d")
            record_item "$s" "yes" "Dev" "$label_prefix ($(project_label "$d"))" "$d"
        done < <(find "$PROJECTS_DIR" -maxdepth "$SCAN_DEPTH" -type d \
            \( -path "*/.next/cache" -o -path "*/android/app/build" -o -path "*/android/build" -o -path "*/ios/build" \) \
            -prune -print0 2>/dev/null)
    fi

    # ── Tool Caches / IDE / System ───────────────────────────────────────
    local brew_cache
    brew_cache=$(brew --cache 2>/dev/null || echo "$HOME/Library/Caches/Homebrew")

    local specs=(
        # Tool Caches
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
        "no|Cache|XDG cache ~/.cache|$HOME/.cache"
        "no|Cache|JetBrains caches|$HOME/Library/Caches/JetBrains"
        "no|Cache|VS Code Cache|$HOME/Library/Application Support/Code/Cache"
        "no|Cache|VS Code CachedData|$HOME/Library/Application Support/Code/CachedData"
        # IDE / Platform
        "yes|IDE|Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData"
        "no|IDE|Xcode Archives|$HOME/Library/Developer/Xcode/Archives"
        "no|IDE|Xcode DeviceSupport|$HOME/Library/Developer/Xcode/iOS DeviceSupport"
        "yes|IDE|CoreSimulator Caches|$HOME/Library/Developer/CoreSimulator/Caches"
        "yes|IDE|Android build cache|$HOME/.android/build-cache"
        # System (user)
        "no|System|User caches ~/Library/Caches|$HOME/Library/Caches"
        "yes|System|User logs|$HOME/Library/Logs"
        "no|System|Trash|$HOME/.Trash"
    )
    local presel cat label path s
    for spec in "${specs[@]}"; do
        IFS='|' read -r presel cat label path <<< "$spec"
        s=$(dir_size_kb "$path")
        record_item "$s" "$presel" "$cat" "$label" "$path" "dir"
    done

    if $ALLOW_SYSTEM; then
        s=$(dir_size_kb "/Library/Caches")
        record_item "$s" "no" "System" "System caches /Library/Caches (sudo)" "/Library/Caches" "dir"
    fi

    # Command-backed cleanup actions
    local brew_estimate
    if command -v brew >/dev/null 2>&1; then
        brew_estimate=$(brew_cleanup_estimate_kb)
        record_item "$brew_estimate" "yes" "Cache" "Homebrew cleanup (-s)" "brew cleanup -s" "command"
    else
        record_item "$(dir_size_kb "$brew_cache")" "yes" "Cache" "Homebrew cache" "$brew_cache" "dir"
    fi

    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local reclaimable_kb
        reclaimable_kb=$(docker_reclaimable_kb)
        record_item "$reclaimable_kb" "no" "System" "Docker system prune" "docker system prune -f" "command"
    fi

    if $DISCOVER_MODE; then
        discover_large_dirs
    fi
}

execute_command_item() {
    local command_label="$1"
    local before_kb after_kb
    case "$command_label" in
        "brew cleanup -s")
            command -v brew >/dev/null 2>&1 || return 1
            before_kb=$(brew_cleanup_estimate_kb)
            brew cleanup -s >/dev/null 2>&1
            after_kb=$(brew_cleanup_estimate_kb)
            echo $(( before_kb - after_kb ))
            ;;
        "docker system prune -f")
            command -v docker >/dev/null 2>&1 || return 1
            docker info >/dev/null 2>&1 || return 1
            before_kb=$(docker_reclaimable_kb)
            docker system prune -f >/dev/null 2>&1
            after_kb=$(docker_reclaimable_kb)
            echo $(( before_kb - after_kb ))
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# Argument parsing
# =============================================================================

DRY_RUN=false
DISCOVER_MODE=false
ALLOW_SYSTEM=false
PRESET="${SWEEP_PRESET:-}"
SCAN_MODE=false
SCAN_RESULTS_FILE=""

while (( $# > 0 )); do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --discover)
            DISCOVER_MODE=true
            shift
            ;;
        --allow-system)
            ALLOW_SYSTEM=true
            shift
            ;;
        --preset)
            [[ -n "${2:-}" ]] || {
                echo "Error: --preset requires a value (safe|balanced|aggressive)" >&2
                exit 1
            }
            PRESET="$2"
            shift 2
            ;;
        --scan)
            [[ -n "${2:-}" ]] || {
                echo "Error: --scan requires an existing results file path" >&2
                exit 1
            }
            SCAN_MODE=true
            SCAN_RESULTS_FILE="$2"
            shift 2
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            echo "Error: unknown option '$1'" >&2
            print_help >&2
            exit 1
            ;;
    esac
done

if [[ -n "$PRESET" ]] && ! validate_preset "$PRESET"; then
    echo "Error: invalid preset '$PRESET' (expected: safe, balanced, aggressive)" >&2
    exit 1
fi

if $SCAN_MODE; then
    if [[ -z "$SCAN_RESULTS_FILE" || ! -f "$SCAN_RESULTS_FILE" ]]; then
        echo "Error: --scan requires an existing results file path" >&2
        exit 1
    fi
    RESULTS_FILE="$SCAN_RESULTS_FILE"
    scan
    exit 0
fi

# =============================================================================
# Main
# =============================================================================

if ! command -v gum >/dev/null 2>&1; then
    echo "Error: gum is required. Install with: brew install gum"
    exit 1
fi

if [[ -z "$PRESET" ]]; then
    PRESET=$(printf '%s\n' "balanced" "safe" "aggressive" | gum choose --header "Pick a cleanup preset")
fi

RESULTS_FILE=$(mktemp)
trap 'rm -f "$RESULTS_FILE"' EXIT

# Header
echo ""
local_suffix=""
$DRY_RUN && local_suffix=" [DRY RUN]"
gum style --foreground 212 --bold "  sweep — disk cleanup (${PRESET} preset)${local_suffix}"
echo ""

# Scan with spinner
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
scan_args=(--scan "$RESULTS_FILE")
$DISCOVER_MODE && scan_args+=(--discover)
$ALLOW_SYSTEM && scan_args+=(--allow-system)

if ! gum spin --spinner dot --title "Scanning for cleanup targets..." -- bash "$SCRIPT_PATH" "${scan_args[@]}"; then
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
    preselect_for_item=$(preset_preselect "$PRESET" "$presel" "$cat")

    SIZES[$i]=$size
    PATHS[$i]=$path
    TYPES[$i]=$type
    DISPLAY[$i]="$(printf '%3d' "$i"). [${cat}] ${label} ($(human_size "$size"))"
    [[ "$preselect_for_item" == "yes" ]] && PRESELECTED+=("${DISPLAY[$i]}")
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
    if [[ "${TYPES[$idx]}" == "command" ]]; then
        gum style --faint "    command: ${PATHS[$idx]}"
    else
        gum style --faint "    ${PATHS[$idx]}"
    fi
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
SUDO_AUTHED=false
for idx in "${DELETE_INDICES[@]}"; do
    path="${PATHS[$idx]}"
    type="${TYPES[$idx]}"

    if [[ "$type" == "command" ]]; then
        gum style --faint "  Running command: $path"
        if freed_from_command=$(execute_command_item "$path"); then
            if (( freed_from_command < 0 )); then
                freed_from_command=0
            fi
            gum style --foreground 2 "  ✓ ${DISPLAY[$idx]}"
            FREED_KB=$(( FREED_KB + freed_from_command ))
        else
            gum style --foreground 1 "  ✗ Command failed: $path"
            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        fi
        continue
    fi

    # Safety: refuse to delete empty, root, or home paths
    if [[ -z "$path" || "$path" == "/" || "$path" == "$HOME" || "$path" == "$HOME/" ]]; then
        gum style --foreground 1 "  ✗ Refused unsafe path: '$path'"
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        continue
    fi

    if ! local_realpath=$(realpath "$path" 2>/dev/null); then
        gum style --foreground 1 "  ✗ Could not resolve path (skipped): '$path'"
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        continue
    fi

    use_sudo=false
    case "$local_realpath" in
        "$HOME"/*)
            ;;
        *)
            if $ALLOW_SYSTEM && is_system_allowlisted_path "$local_realpath"; then
                use_sudo=true
            else
                gum style --foreground 1 "  ✗ Refused path outside \$HOME: '$path'"
                FAIL_COUNT=$(( FAIL_COUNT + 1 ))
                continue
            fi
            ;;
    esac

    if $use_sudo && ! $SUDO_AUTHED; then
        if sudo -v; then
            SUDO_AUTHED=true
        else
            gum style --foreground 1 "  ✗ sudo authentication failed"
            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
            continue
        fi
    fi

    gum style --faint "  Cleaning $(basename "$path")..."
    if $use_sudo; then
        before_kb=$(dir_size_kb_sudo "$path")
        sudo find "$path" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
            | sudo xargs -0 rm -rf 2>/dev/null || true
        after_kb=$(dir_size_kb_sudo "$path")
    else
        before_kb=$(dir_size_kb "$path")
        find "$path" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
            | xargs -0 rm -rf 2>/dev/null || true
        after_kb=$(dir_size_kb "$path")
    fi

    actually_freed=$(( before_kb - after_kb ))

    if (( actually_freed > 0 )); then
        gum style --foreground 2 "  ✓ ${DISPLAY[$idx]} — freed $(human_size "$actually_freed")"
        FREED_KB=$(( FREED_KB + actually_freed ))
    else
        gum style --foreground 3 "  ~ ${DISPLAY[$idx]} — nothing removable (protected)"
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
    fi
done

echo ""
if (( FAIL_COUNT > 0 )); then
    gum style --foreground 3 --bold "  Freed ~$(human_size "$FREED_KB") ($FAIL_COUNT items failed)"
else
    gum style --foreground 2 --bold "  Freed $(human_size "$FREED_KB")!"
fi
echo ""
