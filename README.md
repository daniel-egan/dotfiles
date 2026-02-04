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

## Creating new dotfile

1. Use `chezmoi edit` to open the dotfiles folder
1. Create the folder structure in the `.chezmoitemplates` directory following how it would look within the config sources
    1. The .tmpl extension is optional within this folder
1. Create the template within the `AppData`/`ProgramData`/`dot_config` folder
    1. This must have the `.tmpl` file ending
    1. Make the contents `{{- template "{TEMPLATE_FILE_PATH_HERE}" . -}}` replacing with the location within the `.chezmoitemplates` folder
1. Run `chezmoi apply`
1. If happy with the new dotfiles, run `chezmoi git push`

# Fonts

Currently using `NotoSansM Nerd Font Mono`

- `brew install --cask font-noto-nerd-font`

# Development

Scan folder for secrets with `gitleaks git -v .`
