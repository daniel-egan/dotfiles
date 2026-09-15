# PowerShell dotfiles managed by mise

This repository is a minimal mise-based dotfiles configuration. It currently
manages one PowerShell initialization file:

```text
.
├── mise.toml
└── dotfiles/
    └── powershell/
        └── init.ps1
```

`dotfiles/powershell/init.ps1` is the canonical source. It initializes
zoxide and activates mise in PowerShell:

```powershell
# Initialize Zoxide
Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

# Mise-en-place
(&mise activate pwsh) | Out-String | Invoke-Expression
```

## Platform destinations

`mise.toml` has one `[dotfiles]` entry with platform-specific destination
variants:

| Platform | Destination |
| --- | --- |
| Linux | `~/.config/powershell/init.ps1` |
| Windows | `~/Documents/Powershell/init.ps1` |

The entry uses `mode = "copy"` because PowerShell should receive a regular
configuration file at its platform-specific path while the repository remains
the source of truth. `symlink` would make the deployed file dependent on link
support and link semantics, especially on Windows. `template` is unnecessary
for this first entry because the content does not vary by platform; only the
destination does.

## Prerequisites

Install:

- [mise](https://mise.jdx.dev/)
- PowerShell
- zoxide, if the zoxide initialization line is retained

The `mise` executable must be available on `PATH` when PowerShell starts.

## Commands

The CLI spelling used by this repository and the installed mise version is
`mise dotfiles` (not `mise dot`).

From the repository root:

```bash
# Trust this repository's mise.toml after reviewing it.
mise trust

# Inspect managed entries and their current state.
mise dotfiles status

# Preview the content changes.
mise dotfiles diff

# Preview the copy without changing the live home directory.
mise dotfiles apply --dry-run

# Apply the configured file to the selected platform destination.
mise dotfiles apply
```

`mise dotfiles apply` changes the live destination. Review `status`, `diff`,
and the dry run first, particularly when a destination already exists.

## Validation note

The migration was validated on Linux by parsing `mise.toml` and running the
Linux `status`, `diff`, and dry-run commands. The Windows destination variant
was checked in the parsed configuration, but Windows runtime deployment was
not tested on the Linux runner.

## New machine setup

1. Install mise, PowerShell, and zoxide.
1. Clone this repository and change to its root.
1. Review `mise.toml` and run `mise trust`.
1. Run `mise dotfiles status`, `mise dotfiles diff`, and
   `mise dotfiles apply --dry-run`.
1. Run `mise dotfiles apply` when the planned destination and overwrite
   behavior are acceptable.
1. Start PowerShell and verify that `zoxide` and `mise` are available.

This repository currently contains only the PowerShell entry. Additional
dotfiles should be added as separate canonical sources and explicit
`[dotfiles]` entries after their destinations and deployment mode have been
reviewed.
