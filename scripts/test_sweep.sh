#!/bin/bash

# =============================================================================
# Tests for scripts/sweep.sh
#
# Usage: bash scripts/test_sweep.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWEEP="$SCRIPT_DIR/sweep.sh"

# ASCII unit separator — must match sweep.sh
DELIM=$'\x1f'

PASS=0
FAIL=0
TEST_TMPDIR=""

# =============================================================================
# Test framework
# =============================================================================

setup() {
    TEST_TMPDIR=$(mktemp -d)
}

teardown() {
    [[ -n "$TEST_TMPDIR" && -d "$TEST_TMPDIR" ]] && rm -rf "$TEST_TMPDIR"
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: $desc"
        echo "    expected: '$expected'"
        echo "    actual:   '$actual'"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: $desc"
        echo "    expected to contain: '$needle'"
        echo "    in: '$haystack'"
    fi
}

assert_not_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: $desc"
        echo "    expected NOT to contain: '$needle'"
        echo "    in: '$haystack'"
    fi
}

# Source selected helper functions from sweep.sh
source_helpers() {
    DU_BIN="$(command -v gdu 2>/dev/null || command -v du)"
    eval "$(sed -n '/^human_size()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^dir_size_kb()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^size_fragment_to_kb()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^project_label()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^record_item()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^validate_preset()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^preset_preselect()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^is_system_allowlisted_path()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^path_is_nested_under()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^is_repo_root()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^tmutil_snapshot_count()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^simctl_unavailable_udids()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^simctl_unavailable_estimate_kb()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^simctl_unavailable_count()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^simctl_runtime_unused_ids()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^simctl_runtime_records()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^simctl_runtime_size_kb_by_id()/,/^}$/p' "$SWEEP")"
}

# Run scan mode and return results file path
run_scan() {
    local projects_dir="$1"
    local extra_args="$2"
    local extra_env="$3"
    local results_file="$TEST_TMPDIR/results"
    local fake_home="$TEST_TMPDIR/fakehome"

    mkdir -p "$fake_home"
    : > "$results_file"

    # shellcheck disable=SC2086
    eval "HOME='$fake_home' SWEEP_PROJECTS_DIR='$projects_dir' SWEEP_SCAN_DEPTH=6 ${extra_env} bash '$SWEEP' --scan '$results_file' ${extra_args}"
    echo "$results_file"
}

results_paths() {
    local results_file="$1"
    if [[ -s "$results_file" ]]; then
        while IFS="$DELIM" read -r _size _presel _cat _label path _type _risk _cons _flags; do
            echo "$path"
        done < "$results_file"
    fi
}

results_labels() {
    local results_file="$1"
    if [[ -s "$results_file" ]]; then
        while IFS="$DELIM" read -r _size _presel _cat label _path _type _risk _cons _flags; do
            echo "$label"
        done < "$results_file"
    fi
}

results_raw() {
    local results_file="$1"
    [[ -f "$results_file" ]] && sed -n '1,2000p' "$results_file"
}

# =============================================================================
# Tests: helpers
# =============================================================================

test_human_size() {
    echo "--- helpers: human_size ---"
    source_helpers

    assert_eq "500 KB" "500 KB" "$(human_size 500)"
    assert_eq "1 MB" "1 MB" "$(human_size 1024)"
    assert_eq "2.5 GB" "2.5 GB" "$(human_size 2621440)"
}

test_record_item_sanitizes_delimiter() {
    echo "--- helpers: record_item delimiter sanitize ---"
    setup
    source_helpers

    RESULTS_FILE="$TEST_TMPDIR/results"
    : > "$RESULTS_FILE"

    record_item 100 "yes" "Dev" "bad${DELIM}label" "/tmp/bad${DELIM}path" "dir"
    local line
    line=$(sed -n '1p' "$RESULTS_FILE")
    local _size _presel _cat label path _type risk consequence flags
    IFS="$DELIM" read -r _size _presel _cat label path _type risk consequence flags <<< "$line"
    local field_count
    field_count=$(awk -F "$DELIM" '{print NF}' <<< "$line")

    assert_eq "record has 9 fields" "9" "$field_count"
    assert_not_contains "delimiter stripped from label" "$label" "$DELIM"
    assert_not_contains "delimiter stripped from path" "$path" "$DELIM"
    assert_contains "risk auto-filled" "$risk" "Rebuild"
    assert_contains "consequence auto-filled" "$consequence" "rebuild"

    teardown
}

test_validate_preset_and_preselect() {
    echo "--- helpers: preset validation/preselect ---"
    source_helpers

    if validate_preset "safe" && validate_preset "balanced" && validate_preset "aggressive"; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: valid presets should pass"
    fi

    if validate_preset "nope"; then
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: invalid preset should fail"
    else
        PASS=$(( PASS + 1 ))
    fi

    assert_eq "safe preselect Dev" "yes" "$(preset_preselect safe no Dev)"
    assert_eq "safe preselect Cache" "no" "$(preset_preselect safe yes Cache)"
    assert_eq "balanced uses default" "yes" "$(preset_preselect balanced yes Cache)"
    assert_eq "aggressive selects all" "yes" "$(preset_preselect aggressive no System)"
}

test_system_allowlist_helper() {
    echo "--- helpers: system allowlist ---"
    source_helpers

    if is_system_allowlisted_path "/Library/Caches"; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: /Library/Caches should be allowlisted"
    fi

    if is_system_allowlisted_path "/Library/Caches/com.apple"; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: /Library/Caches/* should be allowlisted"
    fi

    if is_system_allowlisted_path "/etc"; then
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: /etc should not be allowlisted"
    else
        PASS=$(( PASS + 1 ))
    fi
}

test_risk_metadata_in_scan_results() {
    echo "--- scan: risk/consequence metadata ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/repo/node_modules"
    echo "x" > "$TEST_TMPDIR/projects/org/repo/node_modules/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")

    local matched=""
    while IFS="$DELIM" read -r _size _presel _cat label _path _type risk consequence _flags; do
        if [[ "$label" == node_modules* ]]; then
            matched="yes"
            if [[ -n "$risk" ]]; then
                PASS=$(( PASS + 1 ))
            else
                FAIL=$(( FAIL + 1 ))
                echo "  FAIL: risk should be populated"
            fi
            if [[ -n "$consequence" ]]; then
                PASS=$(( PASS + 1 ))
            else
                FAIL=$(( FAIL + 1 ))
                echo "  FAIL: consequence should be populated"
            fi
            break
        fi
    done < "$results"

    if [[ "$matched" == "yes" ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: expected node_modules scan entry"
    fi

    teardown
}

# =============================================================================
# Tests: scan — existing and expanded project artifacts
# =============================================================================

test_scan_finds_existing_artifacts() {
    echo "--- scan: existing artifacts ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/repo/node_modules"
    echo "x" > "$TEST_TMPDIR/projects/org/repo/node_modules/data"

    mkdir -p "$TEST_TMPDIR/projects/org/rust/target"
    echo "x" > "$TEST_TMPDIR/projects/org/rust/target/data"
    touch "$TEST_TMPDIR/projects/org/rust/Cargo.toml"

    mkdir -p "$TEST_TMPDIR/projects/org/flutter/.dart_tool"
    echo "x" > "$TEST_TMPDIR/projects/org/flutter/.dart_tool/data"

    mkdir -p "$TEST_TMPDIR/projects/org/ios/Pods"
    echo "x" > "$TEST_TMPDIR/projects/org/ios/Pods/data"
    touch "$TEST_TMPDIR/projects/org/ios/Podfile"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    local paths
    paths=$(results_paths "$results")

    assert_contains "node_modules found" "$paths" "node_modules"
    assert_contains "target found" "$paths" "/target"
    assert_contains ".dart_tool found" "$paths" ".dart_tool"
    assert_contains "Pods found" "$paths" "/Pods"

    teardown
}

test_scan_dedupes_nested_same_artifacts() {
    echo "--- scan: dedupes nested same artifacts ---"
    setup

    local root="$TEST_TMPDIR/projects/org/repo"
    mkdir -p "$root/node_modules/.pnpm/pkg@1.0.0/node_modules"
    echo "x" > "$root/node_modules/top"
    echo "x" > "$root/node_modules/.pnpm/pkg@1.0.0/node_modules/nested"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")

    local node_modules_count=0
    local path
    while IFS= read -r path; do
        [[ "$path" == *"node_modules"* ]] || continue
        node_modules_count=$(( node_modules_count + 1 ))
    done < <(results_paths "$results")

    assert_eq "only one node_modules entry is shown" "1" "$node_modules_count"

    teardown
}

test_scan_finds_new_artifacts() {
    echo "--- scan: new artifacts ---"
    setup

    local base="$TEST_TMPDIR/projects/org/web"
    mkdir -p "$base/.next/cache"
    mkdir -p "$base/.nuxt"
    mkdir -p "$base/.turbo"
    mkdir -p "$base/.parcel-cache"
    mkdir -p "$base/.svelte-kit"
    mkdir -p "$base/.pytest_cache"
    mkdir -p "$base/.mypy_cache"
    mkdir -p "$base/.ruff_cache"
    mkdir -p "$base/.build"
    touch "$base/Package.swift"

    echo "x" > "$base/.next/cache/data"
    echo "x" > "$base/.nuxt/data"
    echo "x" > "$base/.turbo/data"
    echo "x" > "$base/.parcel-cache/data"
    echo "x" > "$base/.svelte-kit/data"
    echo "x" > "$base/.pytest_cache/data"
    echo "x" > "$base/.mypy_cache/data"
    echo "x" > "$base/.ruff_cache/data"
    echo "x" > "$base/.build/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    local paths
    paths=$(results_paths "$results")

    assert_contains ".next/cache found" "$paths" ".next/cache"
    assert_contains ".nuxt found" "$paths" ".nuxt"
    assert_contains ".turbo found" "$paths" ".turbo"
    assert_contains ".parcel-cache found" "$paths" ".parcel-cache"
    assert_contains ".svelte-kit found" "$paths" ".svelte-kit"
    assert_contains ".pytest_cache found" "$paths" ".pytest_cache"
    assert_contains ".mypy_cache found" "$paths" ".mypy_cache"
    assert_contains ".ruff_cache found" "$paths" ".ruff_cache"
    assert_contains ".build found" "$paths" ".build"

    teardown
}

test_scan_venv_opt_in() {
    echo "--- scan: venv opt-in ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/py/venv"
    mkdir -p "$TEST_TMPDIR/projects/org/py/.venv"
    echo "x" > "$TEST_TMPDIR/projects/org/py/venv/data"
    echo "x" > "$TEST_TMPDIR/projects/org/py/.venv/data"

    local results_no
    results_no=$(run_scan "$TEST_TMPDIR/projects")
    local paths_no
    paths_no=$(results_paths "$results_no")
    assert_not_contains "venv not included by default" "$paths_no" "/venv"
    assert_not_contains ".venv not included by default" "$paths_no" "/.venv"

    local results_yes
    results_yes=$(run_scan "$TEST_TMPDIR/projects" "" "SWEEP_INCLUDE_VENV=true")
    local paths_yes
    paths_yes=$(results_paths "$results_yes")
    assert_contains "venv included when opt-in" "$paths_yes" "/venv"
    assert_contains ".venv included when opt-in" "$paths_yes" "/.venv"

    teardown
}

# =============================================================================
# Tests: discover mode
# =============================================================================

test_discover_mode_finds_large_dirs() {
    echo "--- discover: adds large dirs ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/app/build-output"
    dd if=/dev/zero of="$TEST_TMPDIR/projects/org/app/build-output/blob" bs=1024 count=4 2>/dev/null

    local results
    results=$(run_scan "$TEST_TMPDIR/projects" "--discover" "SWEEP_DISCOVER_MIN_KB=1 SWEEP_DISCOVER_TOP_N=3 SWEEP_DISCOVER_DEPTH=4")
    local raw
    raw=$(results_raw "$results")

    assert_contains "discover category added" "$raw" "${DELIM}Discover${DELIM}"
    assert_contains "discovered path present" "$raw" "build-output"

    teardown
}

test_discover_mode_off_by_default() {
    echo "--- discover: disabled by default ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/app/bigdir"
    dd if=/dev/zero of="$TEST_TMPDIR/projects/org/app/bigdir/blob" bs=1024 count=4 2>/dev/null

    local results
    results=$(run_scan "$TEST_TMPDIR/projects" "" "SWEEP_DISCOVER_MIN_KB=1")
    local raw
    raw=$(results_raw "$results")

    assert_not_contains "no discover entries" "$raw" "${DELIM}Discover${DELIM}"

    teardown
}

test_discover_dedupes_nested_by_default() {
    echo "--- discover: dedupes nested parent/child ---"
    setup

    local root="$TEST_TMPDIR/projects/org/app"
    mkdir -p "$root/parent/child"
    dd if=/dev/zero of="$root/parent/blob" bs=1024 count=4 2>/dev/null
    dd if=/dev/zero of="$root/parent/child/blob" bs=1024 count=2 2>/dev/null

    local results
    results=$(run_scan "$TEST_TMPDIR/projects" "--discover" "SWEEP_DISCOVER_MIN_KB=1 SWEEP_DISCOVER_TOP_N=8 SWEEP_DISCOVER_DEPTH=4 SWEEP_DISCOVER_ROOTS='$root'")
    local paths
    paths=$(results_paths "$results")

    assert_contains "includes parent" "$paths" "$root/parent"
    assert_not_contains "excludes nested child by default" "$paths" "$root/parent/child"

    teardown
}

test_discover_expand_includes_nested_children() {
    echo "--- discover: expand includes nested children ---"
    setup

    local root="$TEST_TMPDIR/projects/org/app"
    mkdir -p "$root/parent/child"
    dd if=/dev/zero of="$root/parent/blob" bs=1024 count=4 2>/dev/null
    dd if=/dev/zero of="$root/parent/child/blob" bs=1024 count=2 2>/dev/null

    local results
    results=$(run_scan "$TEST_TMPDIR/projects" "--discover --discover-expand" "SWEEP_DISCOVER_MIN_KB=1 SWEEP_DISCOVER_TOP_N=8 SWEEP_DISCOVER_DEPTH=4 SWEEP_DISCOVER_ROOTS='$root'")
    local paths
    paths=$(results_paths "$results")

    assert_contains "includes parent" "$paths" "$root/parent"
    assert_contains "includes nested child when expanded" "$paths" "$root/parent/child"

    teardown
}

test_discover_repo_root_marked_inspect() {
    echo "--- discover: repo roots inspect-only ---"
    setup
    source_helpers

    local root="$TEST_TMPDIR/projects/org/app"
    local repo="$root/repo"
    mkdir -p "$repo/.git"
    echo "x" > "$repo/file"
    dd if=/dev/zero of="$repo/blob" bs=1024 count=2 2>/dev/null

    if is_repo_root "$repo"; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: repo root helper should detect .git"
    fi

    local results
    results=$(run_scan "$TEST_TMPDIR/projects" "--discover" "SWEEP_DISCOVER_MIN_KB=1 SWEEP_DISCOVER_TOP_N=8 SWEEP_DISCOVER_DEPTH=4 SWEEP_DISCOVER_ROOTS='$root'")
    local raw
    raw=$(results_raw "$results")

    assert_contains "repo root labeled" "$raw" "Repo root"
    assert_contains "repo root uses inspect type" "$raw" "${DELIM}inspect${DELIM}"
    assert_contains "repo root flag present" "$raw" "${DELIM}repo-root"

    teardown
}

# =============================================================================
# Tests: command-backed items and cache specs
# =============================================================================

test_scan_adds_brew_cleanup_command_item() {
    echo "--- scan: brew cleanup command item ---"
    setup

    mkdir -p "$TEST_TMPDIR/fakehome/Library/Caches/Homebrew"
    dd if=/dev/zero of="$TEST_TMPDIR/fakehome/Library/Caches/Homebrew/blob" bs=1024 count=2 2>/dev/null

    local results_file="$TEST_TMPDIR/results"
    : > "$results_file"
    HOME="$TEST_TMPDIR/fakehome" SWEEP_PROJECTS_DIR="$TEST_TMPDIR/projects" \
        bash "$SWEEP" --scan "$results_file"

    local raw
    raw=$(results_raw "$results_file")
    assert_contains "has brew cleanup label" "$raw" "Homebrew cleanup (-s)"
    assert_contains "has brew command path" "$raw" "brew cleanup -s"
    assert_contains "uses command type" "$raw" "${DELIM}command"

    teardown
}

test_scan_adds_extra_cache_specs() {
    echo "--- scan: extra cache specs ---"
    setup

    mkdir -p "$TEST_TMPDIR/fakehome/.cache"
    mkdir -p "$TEST_TMPDIR/fakehome/Library/Caches/JetBrains"
    mkdir -p "$TEST_TMPDIR/fakehome/Library/Application Support/Code/Cache"
    echo "x" > "$TEST_TMPDIR/fakehome/.cache/data"
    echo "x" > "$TEST_TMPDIR/fakehome/Library/Caches/JetBrains/data"
    echo "x" > "$TEST_TMPDIR/fakehome/Library/Application Support/Code/Cache/data"

    local results_file="$TEST_TMPDIR/results"
    : > "$results_file"
    HOME="$TEST_TMPDIR/fakehome" SWEEP_PROJECTS_DIR="$TEST_TMPDIR/projects" \
        bash "$SWEEP" --scan "$results_file"

    local labels
    labels=$(results_labels "$results_file")
    assert_contains "includes XDG cache" "$labels" "XDG cache ~/.cache"
    assert_contains "includes JetBrains cache" "$labels" "JetBrains caches"
    assert_contains "includes VS Code cache" "$labels" "VS Code Cache"

    teardown
}

# =============================================================================
# Tests: allow-system behavior in scan mode
# =============================================================================

test_scan_allow_system_flag_controls_item() {
    echo "--- scan: --allow-system controls /Library/Caches item ---"
    setup

    local results_no
    results_no=$(run_scan "$TEST_TMPDIR/projects")
    assert_not_contains "without flag no system cache root" "$(results_paths "$results_no")" "/Library/Caches"

    local results_yes
    results_yes=$(run_scan "$TEST_TMPDIR/projects" "--allow-system")
    # Might be absent if size is unreadable/0; assert by label fallback as well
    local raw_yes
    raw_yes=$(results_raw "$results_yes")
    if [[ "$raw_yes" == *"System caches /Library/Caches (sudo)"* || "$raw_yes" == *"/Library/Caches"* ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: expected /Library/Caches target when --allow-system is set"
    fi

    teardown
}

# =============================================================================
# Tests: CLI flags and parsing
# =============================================================================

test_help_flag() {
    echo "--- CLI: --help ---"

    local output
    output=$(bash "$SWEEP" --help 2>&1)
    assert_contains "help shows usage" "$output" "Usage:"
    assert_contains "help shows discover" "$output" "--discover"
    assert_contains "help shows discover-expand" "$output" "--discover-expand"
    assert_contains "help shows preset" "$output" "--preset"
    assert_contains "help shows allow-system" "$output" "--allow-system"
}

test_unknown_flag_fails() {
    echo "--- CLI: unknown flag ---"

    local exit_code=0
    bash "$SWEEP" --nope >/dev/null 2>&1 || exit_code=$?
    if (( exit_code != 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: unknown flag should fail"
    fi
}

test_preset_validation_fails_for_bad_value() {
    echo "--- CLI: bad preset value ---"

    local exit_code=0
    bash "$SWEEP" --preset nope >/dev/null 2>&1 || exit_code=$?
    if (( exit_code != 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: invalid preset should fail"
    fi
}

test_scan_requires_results_file() {
    echo "--- CLI: --scan requires valid file ---"

    local exit_code=0
    bash "$SWEEP" --scan 2>/dev/null || exit_code=$?
    if (( exit_code != 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: --scan without file should fail"
    fi

    exit_code=0
    bash "$SWEEP" --scan "/nonexistent/file" 2>/dev/null || exit_code=$?
    if (( exit_code != 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: --scan with nonexistent file should fail"
    fi
}

test_scan_accepts_multiple_flags() {
    echo "--- CLI: scan accepts multiple flags ---"
    setup

    local results_file="$TEST_TMPDIR/results"
    : > "$results_file"

    local exit_code=0
    SWEEP_PROJECTS_DIR="$TEST_TMPDIR/projects" SWEEP_DISCOVER_MIN_KB=1 \
        bash "$SWEEP" --scan "$results_file" --discover --allow-system || exit_code=$?

    if (( exit_code == 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: expected --scan with multiple flags to succeed"
    fi

    teardown
}

test_scan_accepts_discover_expand_flag() {
    echo "--- CLI: --discover-expand parsing ---"
    setup

    local results_file="$TEST_TMPDIR/results"
    : > "$results_file"

    local root="$TEST_TMPDIR/projects/org/app"
    mkdir -p "$root/parent/child"
    dd if=/dev/zero of="$root/parent/blob" bs=1024 count=3 2>/dev/null
    dd if=/dev/zero of="$root/parent/child/blob" bs=1024 count=2 2>/dev/null

    local exit_code=0
    SWEEP_PROJECTS_DIR="$TEST_TMPDIR/projects" SWEEP_DISCOVER_MIN_KB=1 SWEEP_DISCOVER_TOP_N=8 SWEEP_DISCOVER_DEPTH=4 SWEEP_DISCOVER_ROOTS="$root" \
        bash "$SWEEP" --scan "$results_file" --discover --discover-expand || exit_code=$?

    if (( exit_code == 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: expected --discover-expand to parse in scan mode"
    fi

    assert_contains "expanded output includes nested child" "$(results_paths "$results_file")" "$root/parent/child"

    teardown
}

test_hidden_space_helpers_without_real_tools() {
    echo "--- helpers: hidden-space parsers ---"
    setup
    source_helpers

    tmutil() {
        if [[ "$1" == "listlocalsnapshots" ]]; then
            cat <<'EOF'
Snapshots for disk /:
com.apple.TimeMachine.2026-03-07-101010.local
com.apple.TimeMachine.2026-03-07-111111.local
EOF
        fi
    }

    assert_eq "snapshot count parsed" "2" "$(tmutil_snapshot_count)"

    local fake_home="$TEST_TMPDIR/fakehome"
    HOME="$fake_home"
    mkdir -p "$fake_home/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    mkdir -p "$fake_home/Library/Developer/CoreSimulator/Devices/BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    dd if=/dev/zero of="$fake_home/Library/Developer/CoreSimulator/Devices/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA/blob" bs=1024 count=3 2>/dev/null

    xcrun() {
        if [[ "$1" == "simctl" ]]; then
            cat <<'EOF'
== Devices ==
iPhone 14 (AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA) (Shutdown) (unavailable, runtime profile not found)
EOF
        fi
    }

    assert_eq "unavailable count parsed" "1" "$(simctl_unavailable_count)"
    local estimated
    estimated=$(simctl_unavailable_estimate_kb)
    if (( estimated >= 2 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: expected unavailable simulator estimate to be >= 2 KB"
    fi

    teardown
}

test_sim_runtime_helpers_without_real_tools() {
    echo "--- helpers: simulator runtime parsers ---"
    setup
    source_helpers

    SIM_RUNTIME_UNUSED_DAYS=30
    xcrun() {
        if [[ "$1" == "simctl" && "$2" == "runtime" && "$3" == "list" && "$4" == "-v" ]]; then
            cat <<'EOF'
== Disk Images ==
-- iOS --
iOS 26.0 (23A343) - ACA65F2A-9B99-42B6-A601-4425C3356E6F
    Deletable: YES
    Last Used At: 2026-02-11 12:58:44 +0000
    Size: 7.5G
iOS 26.2 (23C54) - C76040F0-FF67-4C06-9DB9-4D74B8CFE664
    Deletable: YES
    Last Used At: 2026-03-06 13:33:41 +0000
    Size: 7.8G
EOF
        elif [[ "$1" == "simctl" && "$2" == "runtime" && "$3" == "delete" && "$4" == "--notUsedSinceDays" ]]; then
            cat <<'EOF'
Would delete P: ACA65F2A-9B99-42B6-A601-4425C3356E6F iOS (26.0 - 23A343) (Ready)
EOF
        fi
    }

    local records
    records=$(simctl_runtime_records)
    assert_contains "runtime records include first id" "$records" "ACA65F2A-9B99-42B6-A601-4425C3356E6F"
    assert_contains "runtime records include size fragment" "$records" "7.8G"

    local unused
    unused=$(simctl_runtime_unused_ids 30)
    assert_contains "unused ids parser finds dry-run id" "$unused" "ACA65F2A-9B99-42B6-A601-4425C3356E6F"

    local size_kb
    size_kb=$(simctl_runtime_size_kb_by_id "ACA65F2A-9B99-42B6-A601-4425C3356E6F")
    if (( size_kb >= 7000000 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: runtime size helper should parse G suffix"
    fi

    teardown
}

# =============================================================================
# Run all tests
# =============================================================================

echo ""
echo "=== sweep.sh test suite ==="
echo ""

test_human_size
test_record_item_sanitizes_delimiter
test_validate_preset_and_preselect
test_system_allowlist_helper
test_risk_metadata_in_scan_results
test_scan_finds_existing_artifacts
test_scan_dedupes_nested_same_artifacts
test_scan_finds_new_artifacts
test_scan_venv_opt_in
test_discover_mode_finds_large_dirs
test_discover_mode_off_by_default
test_discover_dedupes_nested_by_default
test_discover_expand_includes_nested_children
test_discover_repo_root_marked_inspect
test_scan_adds_brew_cleanup_command_item
test_scan_adds_extra_cache_specs
test_scan_allow_system_flag_controls_item
test_help_flag
test_unknown_flag_fails
test_preset_validation_fails_for_bad_value
test_scan_requires_results_file
test_scan_accepts_multiple_flags
test_scan_accepts_discover_expand_flag
test_hidden_space_helpers_without_real_tools
test_sim_runtime_helpers_without_real_tools

echo ""
if (( FAIL > 0 )); then
    echo "=== RESULT: $PASS passed, $FAIL FAILED ==="
    exit 1
else
    echo "=== RESULT: $PASS passed, 0 failed ==="
fi
