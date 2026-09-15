# Dotfiles managed by mise

This repository contains the mise configuration for setting up my machines.

`mise.toml` is the configuration file. Files that mise deploys live under
`dotfiles/` and are the canonical sources.

## New machine

Install mise first, then run this from the machine you want to set up:

```bash
mise bootstrap --from https://github.com/daniel-egan/dotfiles.git --yes
```

This clones the repository and bootstraps the declared tools and dotfiles
without requiring an interactive review. It applies the current configuration
to the machine, so use the repository branch or commit that contains the
desired setup.

If the repository is already cloned, run this from its root instead:

```bash
mise trust && mise bootstrap --yes
```

The committed `mise.lock` file pins each declared tool to an exact version,
download URL, and checksum for supported platforms. Bootstrap and install use
the lockfile, so machines do not independently resolve different releases.
Refresh it after intentionally changing a tool version:

```bash
mise lock
```

The installed CLI spells dotfile commands as `mise dotfiles`.

## Add a global tool

Add a tool to this repository with `mise use`, using a concrete version:

```bash
mise use --pin ripgrep@14
```

When run from the repository root, `mise use` implicitly updates the project
`mise.toml` and installs the tool on the current machine. `--path mise.toml`
is optional there; use it when running from another directory or when you want
to make the target explicit.

This updates `[tools]`. The version request can be changed to the version you
want to support. Then refresh the lockfile, review both changes, and commit
them so future machines install the same locked release:

```bash
mise lock
```

To add several tools, include them in one command:

```bash
mise use --pin git@2.51.0 fd@10.2.0
```

Use `mise use --pin --dry-run tool@version` first if you want to preview the
change without installing or editing anything. Use `mise lock --dry-run` to
preview lockfile changes.

## Add an application config file

1. Create the canonical source under `dotfiles/`, for example
   `dotfiles/git/config`.
2. Add it with the Mise CLI, selecting the target path and deployment mode:

   ```bash
   mise dotfiles add --mode copy --no-apply \
     --source dotfiles/git/config ~/.config/git/config
   ```

3. Check the generated `[dotfiles]` entry. Add `variants` when Linux and
   Windows need different target paths.
4. Preview the deployment, then apply it:

   ```bash
   mise dotfiles status
   mise dotfiles diff
   mise dotfiles apply --dry-run
   mise dotfiles apply
   ```

`mise dotfiles add` copies the existing target into the canonical source
unless `--source` points to a source you already created. Use `--no-apply` so
adding an entry does not immediately overwrite the live target.

For a platform-specific entry, keep one source and add destination variants to
the generated entry. This repository uses an inline array for variants:

```toml
[dotfiles."app/config"]
source = "dotfiles/app/config"
mode = "copy"
variants = [
  { os = "linux", target = "~/.config/app/config" },
  { os = "windows", target = "~/Documents/app/config" },
]
```

## Choosing a mode

- `copy`: use this when the repository is the source of truth and the
  application should receive a normal file. This is the default choice for
  application config files and works without relying on filesystem links.
- `symlink`: use this when edits made through the deployed path should edit
  the repository source directly and symlinks are suitable on every target
  platform.
- `template`: use this when the file content must be rendered from Mise
  template data. Choose this for content differences, not merely different
  destination paths; use `variants` for destination-only differences.

When unsure, start with `copy`, use `--no-apply`, and review
`mise dotfiles diff` and `mise dotfiles apply --dry-run` before applying.
