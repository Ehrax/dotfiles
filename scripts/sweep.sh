#!/bin/bash

# =============================================================================
# sweep — Interactive disk cleanup for macOS developers
# Usage: sweep [--dry-run] [--discover] [--discover-expand] [--allow-system] [--preset <name>] [--help|-h]
# Requires: gum (brew install gum)
# =============================================================================

set -e

PROJECTS_DIR="${SWEEP_PROJECTS_DIR:-$HOME/Projects}"
SCAN_DEPTH="${SWEEP_SCAN_DEPTH:-5}"
DISCOVER_TOP_N="${SWEEP_DISCOVER_TOP_N:-8}"
DISCOVER_MIN_KB="${SWEEP_DISCOVER_MIN_KB:-524288}"
DISCOVER_DEPTH="${SWEEP_DISCOVER_DEPTH:-3}"
DISCOVER_ROOTS="${SWEEP_DISCOVER_ROOTS:-$PROJECTS_DIR|$HOME/Downloads|$HOME/Library/Developer|$HOME/Library/Caches|$HOME/.cache}"
DISCOVER_EXPAND="${SWEEP_DISCOVER_EXPAND:-false}"
INCLUDE_VENV="${SWEEP_INCLUDE_VENV:-false}"
SNAPSHOT_THIN_BYTES="${SWEEP_SNAPSHOT_THIN_BYTES:-21474836480}"
XCODE_DEVICESUPPORT_KEEP_N="${SWEEP_XCODE_DEVICESUPPORT_KEEP_N:-3}"
SIM_RUNTIME_UNUSED_DAYS="${SWEEP_SIM_RUNTIME_UNUSED_DAYS:-30}"

DU_BIN="$(command -v gdu 2>/dev/null || command -v du)"

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
        result=$("$DU_BIN" -sk "$1" 2>/dev/null)
        echo "${result%%$'\t'*}"
    else
        echo 0
    fi
}

dir_size_kb_sudo() {
    if [[ -d "$1" ]]; then
        local result
        result=$(sudo "$DU_BIN" -sk "$1" 2>/dev/null || true)
        echo "${result%%$'\t'*}"
    else
        echo 0
    fi
}

du_depth_scan_kb() {
    local depth="$1" root="$2"
    if [[ "$(basename "$DU_BIN")" == "gdu" ]]; then
        "$DU_BIN" -k --max-depth="$depth" "$root" 2>/dev/null
    else
        "$DU_BIN" -dk -d "$depth" "$root" 2>/dev/null
    fi
}

search_dirs_by_name() {
    local base_dir="$1" max_depth="$2"
    shift 2
    local names=("$@")
    local raw_results_file deduped_results_file
    raw_results_file=$(mktemp)
    deduped_results_file=$(mktemp)

    if command -v fd >/dev/null 2>&1; then
        local n escaped regex
        local escaped_names=()
        for n in "${names[@]}"; do
            escaped="${n//./\\.}"
            escaped_names+=("$escaped")
        done
        local old_ifs="$IFS"
        IFS='|'
        regex="(^|/)(${escaped_names[*]})$"
        IFS="$old_ifs"
        fd --hidden --follow --no-ignore-vcs --full-path --type d --max-depth "$max_depth" --absolute-path --exclude ".git" "$regex" "$base_dir" 2>/dev/null > "$raw_results_file"
    else
        local find_expr=() n
        for n in "${names[@]}"; do
            find_expr+=( -name "$n" -o )
        done
        unset "find_expr[$(( ${#find_expr[@]} - 1 ))]"
        find "$base_dir" -maxdepth "$max_depth" -type d \( "${find_expr[@]}" \) -prune -print 2>/dev/null > "$raw_results_file"
    fi

    # Match `find ... -prune` behavior for fd path listing: keep parent matches,
    # drop nested matches under an already selected path.
    awk '{ print length($0) "\t" $0 }' "$raw_results_file" | sort -n | cut -f2- > "$deduped_results_file"

    local selected=() candidate parent nested
    while IFS= read -r candidate; do
        [[ -n "$candidate" ]] || continue
        candidate="${candidate%/}"
        nested=false
        for parent in "${selected[@]}"; do
            if path_is_nested_under "$candidate" "$parent"; then
                nested=true
                break
            fi
        done
        if ! $nested; then
            printf '%s\n' "$candidate"
            selected+=("$candidate")
        fi
    done < "$deduped_results_file"

    rm -f "$raw_results_file" "$deduped_results_file"
}

search_dirs_by_path_patterns() {
    local base_dir="$1" max_depth="$2"
    shift 2
    local suffixes=("$@")

    if command -v fd >/dev/null 2>&1; then
        local suffix escaped regex
        local escaped_suffixes=()
        for suffix in "${suffixes[@]}"; do
            escaped="${suffix//./\\.}"
            escaped_suffixes+=("$escaped")
        done
        local old_ifs="$IFS"
        IFS='|'
        regex="(/(${escaped_suffixes[*]}))$"
        IFS="$old_ifs"
        fd --hidden --follow --no-ignore-vcs --full-path --type d --max-depth "$max_depth" --absolute-path --exclude ".git" "$regex" "$base_dir" 2>/dev/null
    else
        local find_expr=() suffix
        for suffix in "${suffixes[@]}"; do
            find_expr+=( -path "*/$suffix" -o )
        done
        unset "find_expr[$(( ${#find_expr[@]} - 1 ))]"
        find "$base_dir" -maxdepth "$max_depth" -type d \( "${find_expr[@]}" \) -prune -print 2>/dev/null
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
    local size="${1:-0}" preselect="$2" category="$3" label="$4" path="$5" type="${6:-dir}" risk="$7" consequence="$8" flags="$9"
    # Sanitize: strip any unit-separator characters from label and path
    label="${label//$DELIM/}"
    path="${path//$DELIM/}"
    risk="${risk//$DELIM/}"
    consequence="${consequence//$DELIM/}"
    flags="${flags//$DELIM/}"

    if [[ -z "$risk" ]]; then
        case "$category" in
            Dev|IDE) risk="Rebuild" ;;
            Cache) risk="Re-download" ;;
            Discover|System|Hidden) risk="Potentially risky" ;;
            *) risk="Safe" ;;
        esac
    fi

    if [[ -z "$consequence" ]]; then
        case "$risk" in
            Safe) consequence="Low risk cleanup; apps recreate data if needed." ;;
            Rebuild) consequence="Removes build artifacts; first rebuild will be slower." ;;
            Re-download) consequence="Removes caches; tools may re-download dependencies." ;;
            "Potentially risky") consequence="May remove important state; inspect before deleting." ;;
            *) consequence="Inspect before deleting." ;;
        esac
    fi

    if (( size > 0 )) || [[ "$type" == "command" || "$type" == "inspect" ]]; then
        printf '%s\n' "${size}${DELIM}${preselect}${DELIM}${category}${DELIM}${label}${DELIM}${path}${DELIM}${type}${DELIM}${risk}${DELIM}${consequence}${DELIM}${flags}" >> "$RESULTS_FILE"
    fi
}

is_path_recorded() {
    local target="$1"
    [[ -s "$RESULTS_FILE" ]] || return 1
    while IFS="$DELIM" read -r _size _presel _cat _label path _type _risk _cons _flags; do
        [[ "$path" == "$target" ]] && return 0
    done < "$RESULTS_FILE"
    return 1
}

path_is_nested_under() {
    local child="$1" parent="$2"
    [[ "$child" == "$parent"/* ]]
}

is_repo_root() {
    local dir="$1"
    [[ -d "$dir/.git" || -f "$dir/.git" ]]
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

size_fragment_to_kb() {
    local fragment="$1"
    if [[ "$fragment" =~ ([0-9.]+)[[:space:]]*G(B)?$ ]]; then
        awk -v val="${BASH_REMATCH[1]}" 'BEGIN {printf "%d", val * 1048576}'
    elif [[ "$fragment" =~ ([0-9.]+)[[:space:]]*M(B)?$ ]]; then
        awk -v val="${BASH_REMATCH[1]}" 'BEGIN {printf "%d", val * 1024}'
    elif [[ "$fragment" =~ ([0-9.]+)[[:space:]]*[kK](B)?$ ]]; then
        awk -v val="${BASH_REMATCH[1]}" 'BEGIN {printf "%d", val * 1000 / 1024}'
    elif [[ "$fragment" =~ ([0-9.]+)[[:space:]]*B ]]; then
        awk -v val="${BASH_REMATCH[1]}" 'BEGIN {printf "%d", val / 1024}'
    else
        echo 0
    fi
}

docker_reclaimable_for_type_kb() {
    local type_name="$1"
    local sum=0 raw_type raw_reclaimable kb
    while IFS='|' read -r raw_type raw_reclaimable; do
        [[ "$raw_type" == "$type_name" ]] || continue
        kb=$(size_fragment_to_kb "$raw_reclaimable")
        sum=$(( sum + kb ))
    done < <(docker system df --format '{{.Type}}|{{.Reclaimable}}' 2>/dev/null)
    echo "$sum"
}

tmutil_snapshot_count() {
    tmutil listlocalsnapshots / 2>/dev/null | awk -F '.' '/com\.apple\.TimeMachine\./ {c++} END {print c+0}'
}

tmutil_snapshot_dates() {
    tmutil listlocalsnapshots / 2>/dev/null | awk -F '.' '/com\.apple\.TimeMachine\./ {print $4}'
}

simctl_unavailable_udids() {
    xcrun simctl list devices unavailable 2>/dev/null | awk '
        /unavailable/ {
            n = split($0, parts, "(")
            for (i = 2; i <= n; i++) {
                split(parts[i], close_parts, ")")
                candidate = close_parts[1]
                if (candidate ~ /^[A-F0-9-]+$/ && length(candidate) == 36) {
                    print candidate
                    break
                }
            }
        }
    '
}

simctl_unavailable_estimate_kb() {
    local devices_dir="$HOME/Library/Developer/CoreSimulator/Devices"
    [[ -d "$devices_dir" ]] || {
        echo 0
        return
    }
    local udid sum=0
    while IFS= read -r udid; do
        [[ -n "$udid" ]] || continue
        sum=$(( sum + $(dir_size_kb "$devices_dir/$udid") ))
    done < <(simctl_unavailable_udids)
    echo "$sum"
}

simctl_unavailable_count() {
    simctl_unavailable_udids | awk 'NF {c++} END {print c+0}'
}

simctl_runtime_unused_ids() {
    local days="${1:-$SIM_RUNTIME_UNUSED_DAYS}"
    xcrun simctl runtime delete --notUsedSinceDays "$days" --dry-run 2>/dev/null \
        | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^[A-F0-9-]{36}$/) print $i}'
}

simctl_runtime_records() {
    xcrun simctl runtime list -v 2>/dev/null | awk '
        function emit() {
            if (id != "" && deletable == "YES") {
                print id "\t" name "\t" size_frag "\t" last_used
            }
        }

        /^[^[:space:]].* - [A-F0-9-]{36}$/ {
            emit()
            line = $0
            sub(/ - [A-F0-9-]{36}$/, "", line)
            match($0, /[A-F0-9-]{36}$/)
            id = substr($0, RSTART, RLENGTH)
            name = line
            size_frag = "0"
            last_used = "unknown"
            deletable = ""
            next
        }

        /^[[:space:]]+Deletable:/ {
            deletable = $2
            next
        }

        /^[[:space:]]+Last Used At:/ {
            sub(/^[[:space:]]+Last Used At:[[:space:]]*/, "", $0)
            last_used = $0
            next
        }

        /^[[:space:]]+Size:/ {
            sub(/^[[:space:]]+Size:[[:space:]]*/, "", $0)
            size_frag = $1
            next
        }

        END {
            emit()
        }
    '
}

simctl_runtime_size_kb_by_id() {
    local target_id="$1"
    local id _name size_frag _last_used
    while IFS=$'\t' read -r id _name size_frag _last_used; do
        [[ "$id" == "$target_id" ]] || continue
        size_fragment_to_kb "$size_frag"
        return
    done < <(simctl_runtime_records)
    echo 0
}

xcode_devicesupport_prune_list() {
    local base="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    local keep_n="${XCODE_DEVICESUPPORT_KEEP_N:-3}"
    [[ -d "$base" ]] || return

    local tmp
    tmp=$(mktemp)
    while IFS= read -r -d '' d; do
        printf '%s\t%s\n' "$(stat -f '%m' "$d" 2>/dev/null || echo 0)" "$d" >> "$tmp"
    done < <(find "$base" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    sort -nr "$tmp" | awk -F '\t' -v keep="$keep_n" 'NR > keep {print $2}'
    rm -f "$tmp"
}

xcode_devicesupport_prune_estimate_kb() {
    local sum=0 d
    while IFS= read -r d; do
        [[ -n "$d" ]] || continue
        sum=$(( sum + $(dir_size_kb "$d") ))
    done < <(xcode_devicesupport_prune_list)
    echo "$sum"
}

discover_large_dirs() {
    local scratch_file
    scratch_file=$(mktemp)

    local old_ifs="$IFS"
    IFS='|'
    read -r -a roots <<< "$DISCOVER_ROOTS"
    IFS="$old_ifs"

    local root found=0
    for root in "${roots[@]}"; do
        [[ -d "$root" ]] || continue
        while IFS=$'\t' read -r s d; do
            [[ -n "$d" ]] || continue
            [[ "$d" == "$root" ]] && continue
            [[ -d "$d" ]] || continue
            # Skip CoreSimulator/Devices — direct rm causes ghost devices;
            # use simctl commands instead (offered separately).
            [[ "$d" == *"/CoreSimulator/Devices"* ]] && continue
            is_path_recorded "$d" && continue
            (( s >= DISCOVER_MIN_KB )) || continue
            printf '%s%s%s\n' "$s" "$DELIM" "$d" >> "$scratch_file"
            found=1
        done < <(du_depth_scan_kb "$DISCOVER_DEPTH" "$root")
    done

    if (( found != 1 )); then
        rm -f "$scratch_file"
        return 0
    fi

    local line count=0 size path
    local selected_parents_file
    selected_parents_file=$(mktemp)
    while IFS="$DELIM" read -r size path; do
        [[ -n "$path" ]] || continue
        if ! is_true "$DISCOVER_EXPAND"; then
            local skip_nested=false p
            while IFS= read -r p; do
                [[ -n "$p" ]] || continue
                if path_is_nested_under "$path" "$p"; then
                    skip_nested=true
                    break
                fi
            done < "$selected_parents_file"
            $skip_nested && continue
        fi

        if is_repo_root "$path"; then
            record_item "$size" "no" "Discover" "Repo root $(short_path "$path")" "$path" "inspect" "Potentially risky" "Git repository root; inspect manually, sweep will skip deletion." "repo-root"
        else
            record_item "$size" "no" "Discover" "Large directory $(short_path "$path")" "$path" "dir" "Potentially risky" "Large discovered directory; verify contents before deleting." ""
        fi
        printf '%s\n' "$path" >> "$selected_parents_file"
        count=$(( count + 1 ))
        (( count >= DISCOVER_TOP_N )) && break
    done < <(sort -nr "$scratch_file")

    rm -f "$scratch_file"
    rm -f "$selected_parents_file"
}

print_help() {
    echo "sweep — Interactive disk cleanup for macOS developers"
    echo ""
    echo "Usage: sweep [--dry-run] [--discover] [--discover-expand] [--allow-system] [--preset <name>] [--help|-h]"
    echo ""
    echo "Options:"
    echo "  --dry-run         Show what would be deleted without deleting"
    echo "  --discover        Include discovered large directory candidates"
    echo "  --discover-expand Include nested discover candidates (no parent/child dedupe)"
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
    echo "  SWEEP_DISCOVER_EXPAND   Set true to include nested discover children"
    echo "  SWEEP_INCLUDE_VENV      Include venv/.venv artifacts in project scan"
    echo "  SWEEP_SIM_RUNTIME_UNUSED_DAYS  Recommend simulator runtime removal after N days (default: 30)"
    echo ""
    echo "Speedups:"
    echo "  Uses fd for faster directory lookup when installed"
    echo "  Uses gdu (GNU du) for faster sizing when installed"
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

        while IFS= read -r d; do
            [[ -n "$d" ]] || continue
            d="${d%/}"
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
        done < <(search_dirs_by_name "$PROJECTS_DIR" "$SCAN_DEPTH" "${names[@]}")

        # Path-based patterns (.next/cache, android/build, android/app/build, ios/build)
        while IFS= read -r d; do
            [[ -n "$d" ]] || continue
            d="${d%/}"
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
        done < <(search_dirs_by_path_patterns "$PROJECTS_DIR" "$SCAN_DEPTH" ".next/cache" "android/app/build" "android/build" "ios/build")
    fi

    # ── Tool Caches / IDE / System ───────────────────────────────────────
    local brew_cache
    brew_cache=$(brew --cache 2>/dev/null || echo "$HOME/Library/Caches/Homebrew")

    local specs=(
        # Tool Caches
        "yes|Cache|npm|$HOME/.npm/_cacache|Re-download|npm cache; packages may need to be fetched again."
        "yes|Cache|Bun|$HOME/.bun/install/cache|Re-download|Bun package cache; dependencies may re-download."
        "yes|Cache|yarn|$HOME/.yarn/cache|Re-download|Yarn cache; packages may re-download."
        "yes|Cache|pnpm store|$HOME/Library/pnpm/store|Re-download|pnpm store cache; packages may re-fetch."
        "yes|Cache|Dart pub|$HOME/.pub-cache|Re-download|Pub cache; Dart/Flutter packages may re-download."
        "yes|Cache|Cargo registry|$HOME/.cargo/registry|Re-download|Cargo registry cache; crates may re-download."
        "no|Cache|CocoaPods repos|$HOME/.cocoapods/repos|Potentially risky|Pod specs repos are removed and recloned later."
        "yes|Cache|Gradle global|$HOME/.gradle/caches|Re-download|Gradle cache; dependencies re-download and rebuild."
        "yes|Cache|pip|$HOME/Library/Caches/pip|Re-download|pip cache; wheels and archives may re-download."
        "no|Cache|FVM Flutter versions|$HOME/.fvm/versions|Potentially risky|Installed Flutter SDK versions are removed."
        "no|Cache|fnm Node versions|$HOME/.local/share/fnm/node-versions|Potentially risky|Installed Node versions are removed."
        "no|Cache|rbenv Ruby versions|$HOME/.rbenv/versions|Potentially risky|Installed Ruby versions are removed."
        "no|Cache|XDG cache ~/.cache|$HOME/.cache|Re-download|General cache data; apps recreate as needed."
        "no|Cache|JetBrains caches|$HOME/Library/Caches/JetBrains|Safe|JetBrains indexes/cache are recreated on launch."
        "no|Cache|VS Code Cache|$HOME/Library/Application Support/Code/Cache|Safe|VS Code cache is recreated on launch."
        "no|Cache|VS Code CachedData|$HOME/Library/Application Support/Code/CachedData|Safe|VS Code cached data is rebuilt as needed."
        # IDE / Platform
        "yes|IDE|Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData|Rebuild|Xcode build products/indexes are rebuilt on next build."
        "no|IDE|Xcode Archives|$HOME/Library/Developer/Xcode/Archives|Potentially risky|Archived app builds are permanently removed."
        "no|IDE|Xcode DeviceSupport|$HOME/Library/Developer/Xcode/iOS DeviceSupport|Potentially risky|Device symbol files are removed and may need re-download."
        "yes|IDE|CoreSimulator Caches|$HOME/Library/Developer/CoreSimulator/Caches|Safe|Simulator caches are recreated automatically."
        "yes|IDE|Android build cache|$HOME/.android/build-cache|Rebuild|Android build cache is regenerated on next build."
        "no|IDE|Android AVDs|$HOME/.android/avd|Potentially risky|Deletes local Android emulators and their device data permanently."
        "no|IDE|Android SDK NDK|$HOME/Library/Android/sdk/ndk|Potentially risky|Installed Android NDK toolchains are removed and may need re-download."
        "no|IDE|Android SDK system-images|$HOME/Library/Android/sdk/system-images|Re-download|Android emulator system images are removed and can be re-downloaded later."
        "no|IDE|Android SDK build-tools|$HOME/Library/Android/sdk/build-tools|Potentially risky|Installed Android build-tools versions are removed and may need re-download."
        # System (user)
        "no|System|User caches ~/Library/Caches|$HOME/Library/Caches|Potentially risky|May clear app caches/sessions; some apps may need re-login."
        "yes|System|User logs|$HOME/Library/Logs|Safe|Log files removed; diagnostics history is lost."
        "no|System|Trash|$HOME/.Trash|Potentially risky|Files in Trash are permanently deleted."
    )
    local presel cat label path risk consequence s
    for spec in "${specs[@]}"; do
        IFS='|' read -r presel cat label path risk consequence <<< "$spec"
        s=$(dir_size_kb "$path")
        record_item "$s" "$presel" "$cat" "$label" "$path" "dir" "$risk" "$consequence" ""
    done

    if $ALLOW_SYSTEM; then
        s=$(dir_size_kb "/Library/Caches")
        record_item "$s" "no" "System" "System caches /Library/Caches (sudo)" "/Library/Caches" "dir" "Potentially risky" "Clears system caches; may impact app/system performance temporarily." ""
    fi

    # Command-backed cleanup actions
    local brew_estimate
    if command -v brew >/dev/null 2>&1; then
        brew_estimate=$(brew_cleanup_estimate_kb)
        record_item "$brew_estimate" "yes" "Cache" "Homebrew cleanup (-s)" "brew cleanup -s" "command" "Safe" "Removes old Homebrew downloads and stale artifacts." ""
    else
        record_item "$(dir_size_kb "$brew_cache")" "yes" "Cache" "Homebrew cache" "$brew_cache" "dir" "Re-download" "Homebrew downloads removed; formulas may re-download." ""
    fi

    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local reclaimable_kb docker_build_kb docker_volume_kb
        reclaimable_kb=$(docker_reclaimable_kb)
        docker_build_kb=$(docker_reclaimable_for_type_kb "Build Cache")
        docker_volume_kb=$(docker_reclaimable_for_type_kb "Local Volumes")
        record_item "$reclaimable_kb" "no" "System" "Docker system prune" "docker system prune -f" "command" "Potentially risky" "Removes unused containers/images/networks and build cache." ""
        record_item "$docker_build_kb" "yes" "System" "Docker builder prune" "docker builder prune -f" "command" "Rebuild" "Clears Docker build cache; next builds may be slower." ""
        record_item "$docker_volume_kb" "no" "System" "Docker volume prune" "docker volume prune -f" "command" "Potentially risky" "Deletes unused volumes and their data permanently." ""
    fi

    if command -v pnpm >/dev/null 2>&1; then
        record_item "$(dir_size_kb "$HOME/Library/pnpm/store")" "yes" "Cache" "pnpm store prune" "pnpm store prune" "command" "Re-download" "Prunes unreferenced pnpm packages from global store." ""
    fi

    if command -v yarn >/dev/null 2>&1; then
        record_item "$(dir_size_kb "$HOME/.yarn/cache")" "yes" "Cache" "yarn cache clean" "yarn cache clean" "command" "Re-download" "Clears Yarn cache; packages may re-download." ""
    fi

    if command -v pip >/dev/null 2>&1; then
        record_item "$(dir_size_kb "$HOME/Library/Caches/pip")" "yes" "Cache" "pip cache purge" "pip cache purge" "command" "Re-download" "Clears pip cache; wheels/packages may re-download." ""
    fi

    local devicesupport_prune_kb
    devicesupport_prune_kb=$(xcode_devicesupport_prune_estimate_kb)
    if (( devicesupport_prune_kb > 0 )); then
        record_item "$devicesupport_prune_kb" "no" "IDE" "Xcode DeviceSupport prune (keep newest $XCODE_DEVICESUPPORT_KEEP_N)" "xcode devicesupport prune" "command" "Potentially risky" "Deletes older DeviceSupport folders; old iOS symbols may need re-download." ""
    fi

    local snapshot_count
    snapshot_count=$(tmutil_snapshot_count)
    if (( snapshot_count > 0 )); then
        record_item 0 "no" "Hidden" "APFS local snapshots thin" "tmutil thinlocalsnapshots / $SNAPSHOT_THIN_BYTES 4" "command" "Safe" "Requests Time Machine to thin local snapshots opportunistically." "advanced"
        record_item 0 "no" "Hidden" "APFS local snapshots delete-all" "tmutil delete-all-local-snapshots" "command" "Potentially risky" "Deletes all local Time Machine snapshots on this disk." "destructive"
    fi

    if command -v xcrun >/dev/null 2>&1; then
        local unavailable_sim_kb unavailable_sim_count
        unavailable_sim_count=$(simctl_unavailable_count)
        unavailable_sim_kb=$(simctl_unavailable_estimate_kb)
        if (( unavailable_sim_count > 0 )); then
            record_item "$unavailable_sim_kb" "yes" "Hidden" "CoreSimulator delete unavailable" "xcrun simctl delete unavailable" "command" "Safe" "Removes unavailable simulators and stale runtimes." ""
        fi

        local runtime_unused_ids_file
        runtime_unused_ids_file=$(mktemp)
        simctl_runtime_unused_ids "$SIM_RUNTIME_UNUSED_DAYS" > "$runtime_unused_ids_file" || true

        local runtime_id runtime_name runtime_size_frag runtime_last_used runtime_size_kb runtime_preselect runtime_label
        while IFS=$'\t' read -r runtime_id runtime_name runtime_size_frag runtime_last_used; do
            [[ -n "$runtime_id" ]] || continue
            runtime_size_kb=$(size_fragment_to_kb "$runtime_size_frag")

            if grep -q "$runtime_id" "$runtime_unused_ids_file"; then
                runtime_preselect="yes"
                runtime_label="Simulator runtime cleanup [recommended unused >=${SIM_RUNTIME_UNUSED_DAYS}d] ${runtime_name} (${runtime_size_frag}, last used: ${runtime_last_used})"
            else
                runtime_preselect="no"
                runtime_label="Simulator runtime cleanup ${runtime_name} (${runtime_size_frag}, last used: ${runtime_last_used})"
            fi

            record_item "$runtime_size_kb" "$runtime_preselect" "Hidden" "$runtime_label" "xcrun simctl runtime delete $runtime_id" "command" "Re-download" "Removes simulator runtime image; it can be re-downloaded from Xcode if needed." ""
        done < <(simctl_runtime_records)

        rm -f "$runtime_unused_ids_file"

        local sim_devices_dir="$HOME/Library/Developer/CoreSimulator/Devices"
        if [[ -d "$sim_devices_dir" ]]; then
            local sim_erase_kb
            sim_erase_kb=$(dir_size_kb "$sim_devices_dir")
            if (( sim_erase_kb > 0 )); then
                record_item "$sim_erase_kb" "no" "Hidden" "CoreSimulator erase all devices" "xcrun simctl shutdown all && xcrun simctl erase all" "command" "Potentially risky" "Shuts down and erases all simulator devices, resetting them to factory state." "destructive"
            fi
        fi
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
        "docker builder prune -f")
            command -v docker >/dev/null 2>&1 || return 1
            docker info >/dev/null 2>&1 || return 1
            before_kb=$(docker_reclaimable_for_type_kb "Build Cache")
            docker builder prune -f >/dev/null 2>&1
            after_kb=$(docker_reclaimable_for_type_kb "Build Cache")
            echo $(( before_kb - after_kb ))
            ;;
        "docker volume prune -f")
            command -v docker >/dev/null 2>&1 || return 1
            docker info >/dev/null 2>&1 || return 1
            before_kb=$(docker_reclaimable_for_type_kb "Local Volumes")
            docker volume prune -f >/dev/null 2>&1
            after_kb=$(docker_reclaimable_for_type_kb "Local Volumes")
            echo $(( before_kb - after_kb ))
            ;;
        "pnpm store prune")
            command -v pnpm >/dev/null 2>&1 || return 1
            before_kb=$(dir_size_kb "$HOME/Library/pnpm/store")
            pnpm store prune >/dev/null 2>&1
            after_kb=$(dir_size_kb "$HOME/Library/pnpm/store")
            echo $(( before_kb - after_kb ))
            ;;
        "yarn cache clean")
            command -v yarn >/dev/null 2>&1 || return 1
            before_kb=$(dir_size_kb "$HOME/.yarn/cache")
            yarn cache clean >/dev/null 2>&1
            after_kb=$(dir_size_kb "$HOME/.yarn/cache")
            echo $(( before_kb - after_kb ))
            ;;
        "pip cache purge")
            command -v pip >/dev/null 2>&1 || return 1
            before_kb=$(dir_size_kb "$HOME/Library/Caches/pip")
            pip cache purge >/dev/null 2>&1
            after_kb=$(dir_size_kb "$HOME/Library/Caches/pip")
            echo $(( before_kb - after_kb ))
            ;;
        "xcode devicesupport prune")
            local ds_base="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
            [[ -d "$ds_base" ]] || return 1
            before_kb=$(dir_size_kb "$ds_base")
            while IFS= read -r old_ds; do
                [[ -n "$old_ds" ]] || continue
                rm -rf "$old_ds"
            done < <(xcode_devicesupport_prune_list)
            after_kb=$(dir_size_kb "$ds_base")
            echo $(( before_kb - after_kb ))
            ;;
        tmutil\ thinlocalsnapshots\ /*)
            command -v tmutil >/dev/null 2>&1 || return 1
            tmutil thinlocalsnapshots / "$SNAPSHOT_THIN_BYTES" 4 >/dev/null 2>&1
            # tmutil does not report reclaimable bytes in a reliable parseable way
            echo 0
            ;;
        "tmutil delete-all-local-snapshots")
            command -v tmutil >/dev/null 2>&1 || return 1
            while IFS= read -r snap_date; do
                [[ -n "$snap_date" ]] || continue
                tmutil deletelocalsnapshots "$snap_date" >/dev/null 2>&1 || return 1
            done < <(tmutil_snapshot_dates)
            echo 0
            ;;
        "xcrun simctl delete unavailable")
            command -v xcrun >/dev/null 2>&1 || return 1
            before_kb=$(simctl_unavailable_estimate_kb)
            xcrun simctl delete unavailable >/dev/null 2>&1
            after_kb=$(simctl_unavailable_estimate_kb)
            echo $(( before_kb - after_kb ))
            ;;
        "xcrun simctl shutdown all && xcrun simctl erase all")
            command -v xcrun >/dev/null 2>&1 || return 1
            local sim_devices_dir="$HOME/Library/Developer/CoreSimulator/Devices"
            before_kb=$(dir_size_kb "$sim_devices_dir")
            xcrun simctl shutdown all >/dev/null 2>&1 || true
            xcrun simctl erase all >/dev/null 2>&1
            after_kb=$(dir_size_kb "$sim_devices_dir")
            echo $(( before_kb - after_kb ))
            ;;
        xcrun\ simctl\ runtime\ delete\ *)
            command -v xcrun >/dev/null 2>&1 || return 1
            local runtime_id
            runtime_id="${command_label##* }"
            before_kb=$(simctl_runtime_size_kb_by_id "$runtime_id")
            xcrun simctl runtime delete "$runtime_id" >/dev/null 2>&1
            after_kb=$(simctl_runtime_size_kb_by_id "$runtime_id")
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
        --discover-expand)
            DISCOVER_EXPAND=true
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
$DISCOVER_MODE && is_true "$DISCOVER_EXPAND" && scan_args+=(--discover-expand)
$ALLOW_SYSTEM && scan_args+=(--allow-system)

if ! gum spin --spinner dot --title "Scanning for cleanup targets..." -- bash "$SCRIPT_PATH" "${scan_args[@]}"; then
    echo "Error: scan phase failed." >&2
    exit 1
fi

# Read results into arrays
SIZES=()
PATHS=()
TYPES=()
RISKS=()
CONSEQUENCES=()
FLAGS=()
DISPLAY=()
PRESELECTED=()
i=0

while IFS="$DELIM" read -r size presel cat label path type risk consequence flags; do
    preselect_for_item=$(preset_preselect "$PRESET" "$presel" "$cat")

    SIZES[$i]=$size
    PATHS[$i]=$path
    TYPES[$i]=$type
    RISKS[$i]="$risk"
    CONSEQUENCES[$i]="$consequence"
    FLAGS[$i]="$flags"
    DISPLAY[$i]="$(printf '%3d' "$i"). [${cat}] [${risk}] ${label} ($(human_size "$size"))"
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
    gum style --faint "    consequence: ${CONSEQUENCES[$idx]}"
    if [[ "${TYPES[$idx]}" == "command" ]]; then
        gum style --faint "    command: ${PATHS[$idx]}"
    elif [[ "${TYPES[$idx]}" == "inspect" ]]; then
        gum style --faint "    inspect-only: ${PATHS[$idx]}"
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
    flags="${FLAGS[$idx]}"

    if [[ "$type" == "inspect" ]] || [[ "$flags" == *"repo-root"* ]]; then
        gum style --foreground 3 "  ! Skipping repo root (inspect-only): $path"
        FAIL_COUNT=$(( FAIL_COUNT + 1 ))
        continue
    fi

    if [[ "$type" == "command" ]]; then
        if [[ "$flags" == *"destructive"* ]]; then
            if ! gum confirm "Destructive action: ${DISPLAY[$idx]}. Type yes by selecting confirm?"; then
                gum style --foreground 3 "  ! Skipped destructive command: $path"
                FAIL_COUNT=$(( FAIL_COUNT + 1 ))
                continue
            fi
        fi
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
