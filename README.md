My custom dotfiles

# Apps
- Nushell
- Neovim

# Usage
## Initialise
```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init daniel-egan --ssh --branch chezmoi
```
## Edit Configs
- `chezmoi edit-config`
- `chezmoi edit-config-template`

# Fonts
Currently using `NotoSansM Nerd Font Mono`
- `brew install --cask font-noto-nerd-font`

# Development
Scan folder for secrets with `gitleaks git -v .`
