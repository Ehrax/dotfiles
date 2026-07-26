# Dotfiles

Personal macOS dotfiles. `./init.sh` installs Homebrew packages and symlinks repository configs directly into live home-directory paths; there is no deploy step.

## Footguns

- `./init.sh` is interactive and host-mutating; do not use it as an unattended check.
- `create_symlink` backs up an existing non-symlink target to `<target>.backup`; an existing backup is preserved, so inspect both paths before modifying or running setup.
- Keep Ghostty on `term = xterm-256color`; some CLI tools mishandle `xterm-ghostty`.

## Checks

- For `scripts/sweep.sh`: `bash scripts/test_sweep.sh`
