# dotfiles

Personal workstation as code.

## What This Repo Does
- Rebuilds shell/editor/git settings with predictable symlinks.
- Backs up existing files before replacing them.
- Restores Homebrew packages from `Brewfile` when needed.

## Managed Files
- `~/.zshrc` -> `zsh/.zshrc`
- `~/.config/zsh/*.zsh` -> `zsh/.config/zsh/*.zsh`
- `~/.gitconfig` -> `git/.gitconfig`
- `~/.gitconfig.local` -> local-only (not tracked)
- `~/.gitignore_global` -> `git/.gitignore_global`
- `~/.tmux.conf` -> `tmux/.tmux.conf`
- `~/.tmux-cheatsheet` -> `tmux/.tmux-cheatsheet`
- `~/.config/nvim` -> `nvim/.config/nvim`
- `~/Library/Application Support/com.mitchellh.ghostty/config` -> `ghostty/.config/ghostty/config`
- `~/.config/karabiner/karabiner.json` -> `karabiner/.config/karabiner/karabiner.json`
- `~/.config/skhd/skhdrc` -> `skhd/.config/skhd/skhdrc`
- Homebrew packages -> `Brewfile`

## Quick Start
```bash
git clone git@github.com:<your-id>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Full Bootstrap (with Homebrew)
```bash
cd ~/dotfiles
./bootstrap.sh --with-brew
```

## Daily Operations
Run dotfiles checks:
```bash
cd ~/dotfiles
./.bin/check.sh
```

Update Homebrew snapshot:
```bash
cd ~/dotfiles
./scripts/update-brewfile.sh
```

Apply latest dotfiles after edits:
```bash
cd ~/dotfiles
./install.sh
```

## Safety Model
- `install.sh` moves existing files into `~/.dotfiles-backup/<timestamp>/` before linking.
- Secrets are intentionally not stored in this repository.
- Runtime secret loading is expected from local-only files under `~/.secrets/`.
- Personal Git identity is kept in `~/.gitconfig.local` and excluded from version control.

## Cloudflare Tunnel Secret File
`cf_tunnel_run` expects a local-only env template at:
- `~/.secrets/cloudflared/op.env`

Minimal example:
```bash
TUNNEL_TOKEN=op://<vault>/cloudflared-tunnel-dev/credential
```

Run:
```bash
cf_tunnel_run
```

## Zsh Structure
`~/.zshrc` is intentionally thin and loads modular files:
- `path.zsh`: PATH and environment variables
- `tools.zsh`: pyenv/rbenv/bun initialization
- `aliases.zsh`: aliases
- `functions.zsh`: shell functions
- `banner.zsh`: interactive banner
- `local.zsh`: machine-specific overrides (local-only)

## Local Scripts
- `./.bin`: shared helper scripts for this dotfiles repo.
- `~/.bin.local`: machine-specific scripts (created by installer, not tracked).
- `path.zsh` adds both `~/dotfiles/.bin` and `~/.bin.local` to `PATH`.

## Git Identity (Local Only)
The installer creates `~/.gitconfig.local` from `git/.gitconfig.local.example` if missing.

```ini
[user]
  name = Your Name
  email = you@example.com
```

## Repository Layout
```text
dotfiles/
├── Brewfile
├── bootstrap.sh
├── ghostty/
├── install.sh
├── git/
├── karabiner/
├── nvim/
├── scripts/
├── skhd/
├── tmux/
└── zsh/
```
