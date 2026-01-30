My custom dotfiles

# Apps

- Nushell
- Neovim

# Usage

## Initialise

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply daniel-egan --ssh --branch chezmoi
```

## Common Commands

- `chezmoi edit` to open the dotfiles config in VS Code
- `chezmoi edit-config` if you typed in one of the prompts wrong
- `chezmoi ignored` to check if you have correctly ignored a folder

# Fonts

Currently using `NotoSansM Nerd Font Mono`

- `brew install --cask font-noto-nerd-font`

# Development

Scan folder for secrets with `gitleaks git -v .`
