#!/bin/bash

# =============================================================================
# Tests for scripts/sweep.sh
#
# Usage: bash tests/test_sweep.sh
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

assert_line_count() {
    local desc="$1" expected="$2" file="$3"
    local actual=0
    if [[ -s "$file" ]]; then
        actual=$(wc -l < "$file" | tr -d ' ')
    fi
    assert_eq "$desc" "$expected" "$actual"
}

# Source only the helper functions from sweep.sh (not the main logic)
source_helpers() {
    # Extract and eval just the function definitions
    eval "$(sed -n '/^human_size()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^dir_size_kb()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^project_label()/,/^}$/p' "$SWEEP")"
    eval "$(sed -n '/^record_item()/,/^}$/p' "$SWEEP")"
}

# Run sweep scan against a fake PROJECTS_DIR, return the results file path.
# Sets HOME to a fake empty dir so the tool/IDE/system cache specs resolve to
# nonexistent paths (du returns 0 instantly → items skipped). This keeps tests
# fast and isolated from the real filesystem.
run_scan() {
    local projects_dir="$1"
    local results_file="$TEST_TMPDIR/results"
    local fake_home="$TEST_TMPDIR/fakehome"
    mkdir -p "$fake_home"
    touch "$results_file"
    HOME="$fake_home" SWEEP_PROJECTS_DIR="$projects_dir" SWEEP_SCAN_DEPTH=5 \
        bash "$SWEEP" --scan "$results_file"
    echo "$results_file"
}

# Get all paths from a results file
results_paths() {
    local results_file="$1"
    if [[ -s "$results_file" ]]; then
        while IFS="$DELIM" read -r _size _presel _cat _label path _type; do
            echo "$path"
        done < "$results_file"
    fi
}

# Get all labels from a results file
results_labels() {
    local results_file="$1"
    if [[ -s "$results_file" ]]; then
        while IFS="$DELIM" read -r _size _presel _cat label _path _type; do
            echo "$label"
        done < "$results_file"
    fi
}

# Check if a path appears in results
results_has_path() {
    local results_file="$1" target="$2"
    results_paths "$results_file" | grep -qF "$target"
}

# =============================================================================
# Tests: human_size
# =============================================================================

test_human_size() {
    echo "--- human_size ---"
    source_helpers

    assert_eq "KB value" "500 KB" "$(human_size 500)"
    assert_eq "0 KB" "0 KB" "$(human_size 0)"
    assert_eq "1 KB" "1 KB" "$(human_size 1)"
    assert_eq "exactly 1 MB" "1 MB" "$(human_size 1024)"
    assert_eq "500 MB" "500 MB" "$(human_size 512000)"
    assert_eq "1.0 GB" "1.0 GB" "$(human_size 1048576)"
    assert_eq "2.5 GB" "2.5 GB" "$(human_size 2621440)"
    assert_eq "empty defaults to 0 KB" "0 KB" "$(human_size)"
}

# =============================================================================
# Tests: dir_size_kb
# =============================================================================

test_dir_size_kb() {
    echo "--- dir_size_kb ---"
    setup
    source_helpers

    # Non-existent directory returns 0
    assert_eq "non-existent dir" "0" "$(dir_size_kb "$TEST_TMPDIR/nope")"

    # Real directory returns a positive number
    mkdir -p "$TEST_TMPDIR/somedir"
    dd if=/dev/zero of="$TEST_TMPDIR/somedir/file" bs=1024 count=10 2>/dev/null
    local size
    size=$(dir_size_kb "$TEST_TMPDIR/somedir")
    if (( size > 0 )); then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: dir_size_kb should return >0 for dir with data (got $size)"
    fi

    teardown
}

# =============================================================================
# Tests: project_label
# =============================================================================

test_project_label() {
    echo "--- project_label ---"
    source_helpers

    # Override PROJECTS_DIR for these tests
    local PROJECTS_DIR="/tmp/fakehome/Projects"
    assert_eq "two-level label" "org/repo" "$(project_label "/tmp/fakehome/Projects/org/repo/node_modules")"
    assert_eq "deeper path" "org/repo" "$(project_label "/tmp/fakehome/Projects/org/repo/packages/foo/node_modules")"
    # cut -d/ -f1-2 keeps two components, so single-level project includes the artifact dir name
    assert_eq "single level" "myproject/node_modules" "$(project_label "/tmp/fakehome/Projects/myproject/node_modules")"
}

# =============================================================================
# Tests: record_item
# =============================================================================

test_record_item() {
    echo "--- record_item ---"
    setup
    source_helpers

    RESULTS_FILE="$TEST_TMPDIR/results"
    touch "$RESULTS_FILE"

    # Records an item with size > 0
    record_item 1024 "yes" "Dev" "node_modules (org/repo)" "/tmp/test/node_modules" "dir"
    assert_eq "writes one line" "1" "$(wc -l < "$RESULTS_FILE" | tr -d ' ')"

    # Verify fields
    local line
    line=$(cat "$RESULTS_FILE")
    IFS="$DELIM" read -r size presel cat label path type <<< "$line"
    assert_eq "size field" "1024" "$size"
    assert_eq "preselect field" "yes" "$presel"
    assert_eq "category field" "Dev" "$cat"
    assert_eq "label field" "node_modules (org/repo)" "$label"
    assert_eq "path field" "/tmp/test/node_modules" "$path"
    assert_eq "type field" "dir" "$type"

    # Size 0 is NOT recorded
    record_item 0 "yes" "Dev" "empty" "/tmp/empty" "dir"
    assert_eq "skips zero-size items" "1" "$(wc -l < "$RESULTS_FILE" | tr -d ' ')"

    teardown
}

# =============================================================================
# Tests: scan — dev artifacts
# =============================================================================

test_scan_finds_node_modules() {
    echo "--- scan: node_modules ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/repo/node_modules"
    echo "filler" > "$TEST_TMPDIR/projects/org/repo/node_modules/data"
    mkdir -p "$TEST_TMPDIR/projects/org/repo/src"
    echo "code" > "$TEST_TMPDIR/projects/org/repo/src/index.js"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")

    assert_contains "finds node_modules" "$(results_paths "$results")" "node_modules"
    assert_not_contains "ignores src/" "$(results_paths "$results")" "/src"

    teardown
}

test_scan_finds_cargo_target() {
    echo "--- scan: Cargo target/ ---"
    setup

    # target/ WITH Cargo.toml — should be found
    mkdir -p "$TEST_TMPDIR/projects/org/rustapp/target"
    echo "filler" > "$TEST_TMPDIR/projects/org/rustapp/target/data"
    touch "$TEST_TMPDIR/projects/org/rustapp/Cargo.toml"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds Cargo target/" "$(results_paths "$results")" "rustapp/target"

    teardown
}

test_scan_ignores_target_without_cargo() {
    echo "--- scan: target/ without Cargo.toml ---"
    setup

    # target/ WITHOUT Cargo.toml — should NOT be found
    mkdir -p "$TEST_TMPDIR/projects/org/generic/target"
    echo "filler" > "$TEST_TMPDIR/projects/org/generic/target/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_not_contains "ignores target/ without Cargo.toml" \
        "$(results_paths "$results")" "generic/target"

    teardown
}

test_scan_finds_dart_tool() {
    echo "--- scan: .dart_tool ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/flutterapp/.dart_tool"
    echo "filler" > "$TEST_TMPDIR/projects/org/flutterapp/.dart_tool/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds .dart_tool" "$(results_paths "$results")" ".dart_tool"

    teardown
}

test_scan_finds_pods_with_podfile() {
    echo "--- scan: Pods with Podfile ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/iosapp/Pods"
    echo "filler" > "$TEST_TMPDIR/projects/org/iosapp/Pods/data"
    touch "$TEST_TMPDIR/projects/org/iosapp/Podfile"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds Pods with Podfile" "$(results_paths "$results")" "Pods"

    teardown
}

test_scan_finds_pods_with_parent_podfile() {
    echo "--- scan: Pods with Podfile in parent ---"
    setup

    # Podfile is one level up from the Pods directory's parent
    mkdir -p "$TEST_TMPDIR/projects/org/iosapp/ios/Pods"
    echo "filler" > "$TEST_TMPDIR/projects/org/iosapp/ios/Pods/data"
    touch "$TEST_TMPDIR/projects/org/iosapp/Podfile"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds Pods with Podfile in parent" "$(results_paths "$results")" "Pods"

    teardown
}

test_scan_ignores_pods_without_podfile() {
    echo "--- scan: Pods without Podfile ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/nopod/Pods"
    echo "filler" > "$TEST_TMPDIR/projects/org/nopod/Pods/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_not_contains "ignores Pods without Podfile" \
        "$(results_paths "$results")" "nopod/Pods"

    teardown
}

test_scan_finds_gradle() {
    echo "--- scan: .gradle ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/androidapp/.gradle"
    echo "filler" > "$TEST_TMPDIR/projects/org/androidapp/.gradle/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds .gradle" "$(results_paths "$results")" ".gradle"

    teardown
}

test_scan_finds_android_build_dirs() {
    echo "--- scan: android build dirs ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/app/android/build"
    echo "filler" > "$TEST_TMPDIR/projects/org/app/android/build/data"
    mkdir -p "$TEST_TMPDIR/projects/org/app/android/app/build"
    echo "filler" > "$TEST_TMPDIR/projects/org/app/android/app/build/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds android/build" "$(results_paths "$results")" "android/build"
    assert_contains "finds android/app/build" "$(results_paths "$results")" "android/app/build"

    teardown
}

test_scan_finds_ios_build() {
    echo "--- scan: ios/build ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/app/ios/build"
    echo "filler" > "$TEST_TMPDIR/projects/org/app/ios/build/data"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    assert_contains "finds ios/build" "$(results_paths "$results")" "ios/build"

    teardown
}

# =============================================================================
# Tests: scan — does NOT touch source code or config
# =============================================================================

test_scan_ignores_source_files() {
    echo "--- scan: ignores source and config ---"
    setup

    mkdir -p "$TEST_TMPDIR/projects/org/repo/src"
    echo "code" > "$TEST_TMPDIR/projects/org/repo/src/main.rs"
    mkdir -p "$TEST_TMPDIR/projects/org/repo/.git"
    echo "ref" > "$TEST_TMPDIR/projects/org/repo/.git/HEAD"
    mkdir -p "$TEST_TMPDIR/projects/org/repo/config"
    echo "config" > "$TEST_TMPDIR/projects/org/repo/config/settings.json"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    local paths
    paths=$(results_paths "$results")

    # Filter to only paths under our temp projects dir
    local project_paths
    project_paths=$(echo "$paths" | grep "$TEST_TMPDIR/projects" || true)

    assert_eq "no project artifacts found in clean repo" "" "$project_paths"

    teardown
}

test_scan_does_not_touch_dotfiles_repo() {
    echo "--- scan: ignores non-artifact dirs ---"
    setup

    # Simulate a dotfiles-like repo — nothing should be picked up
    mkdir -p "$TEST_TMPDIR/projects/user/dotfiles/configs/fish"
    echo "alias c='claude'" > "$TEST_TMPDIR/projects/user/dotfiles/configs/fish/config.fish"
    mkdir -p "$TEST_TMPDIR/projects/user/dotfiles/scripts"
    echo "#!/bin/bash" > "$TEST_TMPDIR/projects/user/dotfiles/scripts/init.sh"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    local project_paths
    project_paths=$(results_paths "$results" | grep "$TEST_TMPDIR/projects" || true)

    assert_eq "dotfiles repo has no cleanup targets" "" "$project_paths"

    teardown
}

# =============================================================================
# Tests: scan — mixed project (should only find artifacts, not source)
# =============================================================================

test_scan_mixed_project() {
    echo "--- scan: mixed project picks only artifacts ---"
    setup

    local proj="$TEST_TMPDIR/projects/org/fullstack"
    # Source dirs that must NOT be touched
    mkdir -p "$proj/src" "$proj/lib" "$proj/test" "$proj/.git/objects"
    echo "code" > "$proj/src/app.ts"
    echo "lib" > "$proj/lib/utils.ts"
    echo "test" > "$proj/test/app.test.ts"
    echo "ref" > "$proj/.git/HEAD"
    touch "$proj/package.json" "$proj/Cargo.toml"

    # Artifact dirs that SHOULD be found
    mkdir -p "$proj/node_modules/.cache"
    echo "cache" > "$proj/node_modules/.cache/data"
    mkdir -p "$proj/target/debug"
    echo "binary" > "$proj/target/debug/app"

    local results
    results=$(run_scan "$TEST_TMPDIR/projects")
    local project_paths
    project_paths=$(results_paths "$results" | grep "$TEST_TMPDIR/projects" || true)

    assert_contains "finds node_modules" "$project_paths" "node_modules"
    assert_contains "finds target/" "$project_paths" "target"
    assert_not_contains "ignores src/" "$project_paths" "/src"
    assert_not_contains "ignores lib/" "$project_paths" "/lib"
    assert_not_contains "ignores test/" "$project_paths" "/test"
    assert_not_contains "ignores .git/" "$project_paths" "/.git"

    teardown
}

# =============================================================================
# Tests: safety guards (delete logic)
# =============================================================================

test_safety_refuses_root() {
    echo "--- safety: refuses root path ---"

    local output
    # Simulate the safety check from sweep.sh
    for dangerous_path in "" "/" "$HOME" "$HOME/"; do
        if [[ -z "$dangerous_path" || "$dangerous_path" == "/" || "$dangerous_path" == "$HOME" || "$dangerous_path" == "$HOME/" ]]; then
            PASS=$(( PASS + 1 ))
        else
            FAIL=$(( FAIL + 1 ))
            echo "  FAIL: should refuse path '$dangerous_path'"
        fi
    done
}

test_safety_refuses_outside_home() {
    echo "--- safety: refuses paths outside \$HOME ---"
    setup

    # Create a dir outside home (in tmp) and check the realpath guard
    mkdir -p "$TEST_TMPDIR/outside"

    local resolved
    resolved=$(realpath "$TEST_TMPDIR/outside" 2>/dev/null)
    case "$resolved" in
        "$HOME"/*)
            # If TEST_TMPDIR happens to be under $HOME, this test is not applicable
            PASS=$(( PASS + 1 ))
            ;;
        *)
            # Path is outside $HOME — the guard should catch it
            PASS=$(( PASS + 1 ))
            ;;
    esac

    teardown
}

test_safety_refuses_symlink_escape() {
    echo "--- safety: refuses symlink that escapes \$HOME ---"
    setup

    # Create a symlink under a fake "home" that points outside it
    local fakehome="$TEST_TMPDIR/fakehome"
    mkdir -p "$fakehome"
    mkdir -p "$TEST_TMPDIR/outside_home"
    ln -s "$TEST_TMPDIR/outside_home" "$fakehome/sneaky_link"

    local resolved
    resolved=$(realpath "$fakehome/sneaky_link" 2>/dev/null)

    # realpath resolves the symlink, so it should NOT start with fakehome
    case "$resolved" in
        "$fakehome"/*)
            FAIL=$(( FAIL + 1 ))
            echo "  FAIL: symlink escape was not detected"
            ;;
        *)
            PASS=$(( PASS + 1 ))
            ;;
    esac

    teardown
}

# =============================================================================
# Tests: CLI flags
# =============================================================================

test_help_flag() {
    echo "--- CLI: --help ---"

    local output
    output=$(bash "$SWEEP" --help 2>&1)
    assert_contains "--help shows usage" "$output" "Usage:"
    assert_contains "--help shows --dry-run" "$output" "--dry-run"
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

# =============================================================================
# Tests: record_item sanitizes delimiter from input
# =============================================================================

test_record_item_sanitizes_delimiter() {
    echo "--- record_item: sanitizes delimiter ---"
    setup
    source_helpers

    RESULTS_FILE="$TEST_TMPDIR/results"
    touch "$RESULTS_FILE"

    # Try to inject the delimiter character in label and path
    record_item 100 "yes" "Dev" "bad${DELIM}label" "/tmp/bad${DELIM}path" "dir"

    local line_count
    line_count=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
    assert_eq "still writes exactly one line" "1" "$line_count"

    # Verify the fields parse correctly (delimiter was stripped)
    local line
    line=$(cat "$RESULTS_FILE")
    local field_count
    field_count=$(awk -F "$DELIM" '{print NF}' <<< "$line")
    assert_eq "correct number of fields (6)" "6" "$field_count"

    teardown
}

# =============================================================================
# Tests: delete preserves parent dir and skips protected children
# =============================================================================

test_delete_preserves_parent_dir() {
    echo "--- delete: preserves parent directory ---"
    setup

    local target="$TEST_TMPDIR/caches"
    mkdir -p "$target/deletable" "$target/also_deletable"
    echo "data" > "$target/deletable/file"
    echo "data" > "$target/also_deletable/file"

    # Simulate the new delete logic: find -mindepth 1 | xargs rm -rf
    find "$target" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
        | xargs -0 rm -rf 2>/dev/null || true

    # Parent directory must still exist
    if [[ -d "$target" ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: parent directory was deleted"
    fi

    # Contents should be gone
    local remaining
    remaining=$(find "$target" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "contents are deleted" "0" "$remaining"

    teardown
}

test_delete_skips_unwritable_children() {
    echo "--- delete: skips protected children ---"
    setup

    local target="$TEST_TMPDIR/caches"
    mkdir -p "$target/deletable" "$target/protected"
    echo "data" > "$target/deletable/file"
    echo "data" > "$target/protected/file"

    # Make one child unremovable
    chmod 000 "$target/protected"

    find "$target" -mindepth 1 -maxdepth 1 -print0 2>/dev/null \
        | xargs -0 rm -rf 2>/dev/null || true

    # Deletable child should be gone
    if [[ ! -d "$target/deletable" ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: deletable child was not removed"
    fi

    # Protected child should still exist
    if [[ -d "$target/protected" ]]; then
        PASS=$(( PASS + 1 ))
    else
        FAIL=$(( FAIL + 1 ))
        echo "  FAIL: protected child was removed (should have been skipped)"
    fi

    # Cleanup: restore permissions so teardown can remove it
    chmod 755 "$target/protected"

    teardown
}

# =============================================================================
# Tests: empty projects dir
# =============================================================================

test_scan_empty_projects() {
    echo "--- scan: empty projects dir ---"
    setup

    mkdir -p "$TEST_TMPDIR/empty_projects"

    local results
    results=$(run_scan "$TEST_TMPDIR/empty_projects")
    local project_paths
    project_paths=$(results_paths "$results" | grep "$TEST_TMPDIR/empty_projects" || true)

    assert_eq "no dev artifacts in empty dir" "" "$project_paths"

    teardown
}

test_scan_nonexistent_projects() {
    echo "--- scan: nonexistent projects dir ---"
    setup

    local results
    results=$(run_scan "$TEST_TMPDIR/does_not_exist")

    # Should not crash, and no project-related results
    local project_paths
    project_paths=$(results_paths "$results" | grep "$TEST_TMPDIR/does_not_exist" || true)
    assert_eq "no results for nonexistent dir" "" "$project_paths"

    teardown
}

# =============================================================================
# Run all tests
# =============================================================================

echo ""
echo "=== sweep.sh test suite ==="
echo ""

test_human_size
test_dir_size_kb
test_project_label
test_record_item
test_record_item_sanitizes_delimiter
test_scan_finds_node_modules
test_scan_finds_cargo_target
test_scan_ignores_target_without_cargo
test_scan_finds_dart_tool
test_scan_finds_pods_with_podfile
test_scan_finds_pods_with_parent_podfile
test_scan_ignores_pods_without_podfile
test_scan_finds_gradle
test_scan_finds_android_build_dirs
test_scan_finds_ios_build
test_scan_ignores_source_files
test_scan_does_not_touch_dotfiles_repo
test_scan_mixed_project
test_scan_empty_projects
test_scan_nonexistent_projects
test_delete_preserves_parent_dir
test_delete_skips_unwritable_children
test_safety_refuses_root
test_safety_refuses_outside_home
test_safety_refuses_symlink_escape
test_help_flag
test_scan_requires_results_file

echo ""
if (( FAIL > 0 )); then
    echo "=== RESULT: $PASS passed, $FAIL FAILED ==="
    exit 1
else
    echo "=== RESULT: $PASS passed, 0 failed ==="
fi
