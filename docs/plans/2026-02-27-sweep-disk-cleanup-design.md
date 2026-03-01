# sweep — Interactive Disk Cleanup TUI

## Context

Developer machines accumulate massive amounts of cache and build artifacts across projects. With Flutter/FVM, React Native, Rust/Cargo, Ionic, Node.js, Xcode, and Android Studio all in play, it's easy to lose 50GB+ to stale `node_modules/`, `target/`, `DerivedData`, and tool caches.

Evaluated existing tools ([Mole](https://github.com/tw93/Mole), [mac-cleanup-go](https://github.com/2ykwang/mac-cleanup-go), [dev-cleaner](https://github.com/jemishavasoya/dev-cleaner), [mac-cleanup-py](https://github.com/mac-cleanup/mac-cleanup-py)) — none cover the exact stack (FVM, Bun, Ionic, fnm) and all are opaque binaries. Decision: build a custom ~350-line bash script using `gum` for the TUI. Lives in dotfiles, version-controlled, every target is a single line to add/remove.

## Files

| File | Action |
|------|--------|
| `scripts/sweep.sh` | Main cleanup script |
| `configs/fish/config.fish` | `sweep` alias |
| `Brewfile` | `gum` dependency |

## Flow

```
sweep [--dry-run]
  ├─ 1. Check gum is installed
  ├─ 2. Scan all categories (gum spin spinner)
  ├─ 3. Present results with gum choose --no-limit (checkboxes)
  ├─ 4. Show total selected size
  ├─ 5. Confirm with gum confirm
  └─ 6. Delete selected items
```

## Cleanup Targets

Safe items are pre-checked; risky items require opt-in.

### Dev Artifacts (recursive ~/Projects)

- `node_modules/` — pre-selected
- `target/` (Rust, only with Cargo.toml) — pre-selected
- `.dart_tool/` — pre-selected
- `android/app/build` — pre-selected
- `android/build` — pre-selected
- `ios/build` — pre-selected
- `Pods/` (only with Podfile) — pre-selected
- `.gradle/` (project-level) — pre-selected

### Tool Caches

- Homebrew, npm, Bun, yarn, pnpm, Dart pub, Cargo registry, Gradle global, pip — pre-selected
- CocoaPods repos — opt-in (slow to re-clone)

### IDE / Platform

- Xcode DerivedData, CoreSimulator Caches, Android build cache — pre-selected
- Xcode Archives, DeviceSupport — opt-in

### System

- User logs — pre-selected
- User caches, Trash, Docker — opt-in
