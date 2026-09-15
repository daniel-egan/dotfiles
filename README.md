# Dotfiles managed by mise

This repository is a minimal starting point for managing a machine with mise.
The main configuration file is `mise.toml`. It can declare:

- dotfiles and their deployment targets
- tools that mise should install
- host packages managed by supported package managers
- bootstrap behavior for putting a machine into the desired state

The repository currently contains one dotfile entry and two tool declarations.
The PowerShell initialization file is a small example:

```text
.
|-- mise.toml
`-- dotfiles/
    `-- powershell/
        `-- init.ps1
```

The file under `dotfiles/` is the canonical source. The current `[dotfiles]`
entry copies it to a platform-specific destination. Future entries can add
other files without changing this source layout.

## Platform variants

An entry can use `variants` to select a destination for the current operating
system. For example, one source can target:

| Platform | Example destination |
| --- | --- |
| Linux | `~/.config/example/config` |
| Windows | `~/Documents/example/config` |

The most specific matching variant is selected. Keep a default variant or
otherwise ensure that each supported platform has an intentional destination.
The current configuration uses Linux and Windows variants for the PowerShell
example.

## Modes

Dotfiles can use different deployment modes:

- `copy` writes a regular file at the target. This is the current mode and is
  useful when the target should not depend on link support.
- `symlink` links the target to the source. This can be useful when edits at
  the target should update the repository source directly.
- `template` renders a source before deployment. Use it when content depends
  on platform or other Mise template data.

Choose the mode per entry and review the effect before applying it.

## Prerequisites and declarations

Install mise and make it available on `PATH`. The current `[tools]` table
declares pinned PowerShell and zoxide versions, so mise can install those
tools. No host packages are currently declared under `[bootstrap.packages]`.

When needed, add more tools under `[tools]`; mise can then install those
declared tools. Add host package declarations under `[bootstrap.packages]` when
a supported package manager should install system dependencies. Do not assume a
tool or package is installed until its declaration and installation has been
verified.

## Safe workflow

The installed CLI uses `mise dotfiles` for dotfile operations:

```bash
# Review the configuration before trusting it.
mise trust
mise config get --file mise.toml

# Inspect the selected entries and planned changes.
mise dotfiles status
mise dotfiles diff
mise dotfiles apply --dry-run

# Apply only after reviewing the dry-run output.
mise dotfiles apply
```

`mise dotfiles apply` changes live target files. Use the dry run first,
especially when a target already exists. On a new machine, clone the
repository, review `mise.toml`, trust it, inspect status and diff, and run the
dry run before applying.

## Bootstrap workflow

As this repository grows, `mise bootstrap` can coordinate the declared
machine state, including packages, tools, repositories, dotfiles, and other
configured resources. Preview the complete bootstrap plan before applying it:

```bash
mise bootstrap status
mise bootstrap --dry-run
mise bootstrap --only dotfiles --dry-run
```

When the plan is understood, apply the selected scope:

```bash
mise bootstrap --only dotfiles
mise bootstrap
```

The current configuration has `[tools]` declarations but no
`[bootstrap.packages]` declarations. Bootstrap can therefore install the
declared tools when that phase is selected, while host package installation
remains a future configuration change.
