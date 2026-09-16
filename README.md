# Dotfiles managed by mise

This repository contains my mise configuration for tools and dotfiles. Mise
uses `mise.toml` to install the declared tools and deploy files from
`dotfiles/`. `mise.lock` pins tool versions for supported platforms.

## New machine

Install mise, then run this command on the machine:

```bash
mise bootstrap --from https://github.com/daniel-egan/dotfiles.git --yes
```

If the repository is already cloned, run these commands from its root:

```bash
mise trust
mise bootstrap --yes
```

Review the dotfile changes before applying them:

```bash
mise dotfiles status
mise dotfiles diff
mise dotfiles apply --dry-run
```

`mise dotfiles diff` compares the configured files with their current targets.
The dry run shows the actions without changing files.

Apply the configuration with:

```bash
mise dotfiles apply
```

If a target already exists and is not the expected symlink, Mise stops instead
of replacing it. To replace conflicting dotfiles during bootstrap, use:

```bash
mise bootstrap --yes --force-dotfiles
```

The repository declares the tools and dotfiles used on my machines. Add or
change tools in `mise.toml`, then refresh the lockfile with `mise lock`.

## Git identity

The Git config is a Mise template. It reads `GIT_USER_NAME` and
`GIT_USER_EMAIL` when it renders the deployed Git config. If either variable is
unset, the template uses `daniel-egan` and
`95421705+daniel-egan@users.noreply.github.com`.

Set these variables before checking or applying the configuration when the
machine needs a different identity:

```bash
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="you@example.com"
mise dotfiles diff
mise dotfiles apply --dry-run
```

Edit `dotfiles/git/config.tmpl` to change the Git config template. The
deployed Git config is generated from that template.
