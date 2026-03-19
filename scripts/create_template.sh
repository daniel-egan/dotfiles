#!/usr/bin/env bash
# create_template.sh
#
# Purpose:
#   Take a "canonical" directory tree or single file (e.g. a LazyVim starter clone or a config file)
#   and make it your single source of truth inside chezmoi's .chezmoitemplates,
#   then generate thin wrapper *.tmpl files in one or more chezmoi source-state
#   target directories that just include those templates.
#
# Example:
#   ./create_template.sh /tmp/starter home/.chezmoitemplates/neovim home/dot_config/nvim AppData/Local/nvim
#
# What it does:
#   1) Copies /tmp/starter/** -> home/.chezmoitemplates/neovim/**
#   2) Creates wrapper templates:
#        home/dot_config/nvim/<path>.tmpl        containing {{- template "neovim/<path>" . -}}
#        AppData/Local/nvim/<path>.tmpl          containing {{- template "neovim/<path>" . -}}
#
# Notes:
#   - Run this from your chezmoi source directory (i.e. after `chezmoi cd`),
#     because paths like `home/...` are relative to the source state root.
#   - It skips the source .git directory by default.
#   - It will not overwrite existing wrappers unless you pass --force.
#   - Requires bash 4+ (uses mapfile/readarray). macOS users: install bash
#     via Homebrew and ensure /usr/local/bin/bash or /opt/homebrew/bin/bash
#     is in your PATH ahead of the system bash 3.2.
#
set -euo pipefail

# --- Globals ---

force=0
dry_run=0
verbose=0
declare -a skip_patterns=(".git")
declare -a created_dirs=()   # Track dirs we create, for cleanup on failure

# --- Color helpers (disabled if stdout is not a terminal) ---

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'   GREEN=$'\033[0;32m'  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'  BOLD=$'\033[1m'      RESET=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

log_info()  { echo "${BLUE}==>${RESET} $*"; }
log_ok()    { echo "${GREEN}==>${RESET} $*"; }
log_warn()  { echo "${YELLOW}WARN:${RESET} $*" >&2; }
log_error() { echo "${RED}ERROR:${RESET} $*" >&2; }
log_verb()  { (( verbose )) && echo "    $*" || true; }

# --- Cleanup on failure ---

cleanup() {
  local exit_code=$?
  if (( exit_code != 0 )); then
    log_error "Script failed (exit $exit_code). Cleaning up partially-created directories..."
    for d in "${created_dirs[@]}"; do
      if [[ -d "$d" ]]; then
        rm -rf "$d"
        log_verb "Removed: $d"
      fi
    done
    log_error "Cleanup complete. No changes were persisted."
  fi
}

trap cleanup EXIT

# --- Usage ---

usage() {
  cat <<'EOF'
Usage:
  create_template.sh [OPTIONS] <source_path> <templates_dest_dir> <target_dir1> [target_dir2 ...]

Arguments:
  source_path          File or directory on your OS to import (e.g. /tmp/starter or /path/to/config.lua)
  templates_dest_dir   Where to copy it under your chezmoi source state (under home/),
                       e.g. .chezmoitemplates/neovim (will be prefixed with home/)
  target_dirN          One or more chezmoi source-state directories where
                       wrappers should be created (under home/),
                       e.g. dot_config/nvim AppData/Local/nvim (will be prefixed with home/)

Options:
  -h, --help           Show this help message
  -n, --dry-run        Show what would be done without making any changes
  -v, --verbose        Print each file as it is created or skipped
  -f, --force          Overwrite existing wrapper .tmpl files
  --skip PATTERN       Additional path patterns (relative to source_path)
                       to skip. Can be repeated.

Examples:
  ./create_template.sh /tmp/starter .chezmoitemplates/neovim dot_config/nvim AppData/Local/nvim
  ./create_template.sh --force --skip '.git' --skip 'lazy-lock.json' /tmp/starter .chezmoitemplates/neovim dot_config/nvim
  ./create_template.sh --dry-run -v /tmp/starter .chezmoitemplates/neovim dot_config/nvim
  ./create_template.sh /path/to/config.lua .chezmoitemplates/lua-config dot_config/lua/config.lua
EOF
}

# --- Argument parsing ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    -f|--force)   force=1; shift ;;
    -n|--dry-run) dry_run=1; shift ;;
    -v|--verbose) verbose=1; shift ;;
    --skip)
      [[ $# -ge 2 ]] || { log_error "--skip requires a pattern"; exit 2; }
      skip_patterns+=("$2")
      shift 2
      ;;
    --)  shift; break ;;
    -*)
      log_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
    *)   break ;;
  esac
done

[[ $# -ge 3 ]] || { usage >&2; exit 2; }

src_path="$1"
templates_dest="$2"
shift 2
targets=("$@")

# Prepend 'home/' if not present, assuming .chezmoiroot is home
if [[ "$templates_dest" != home/* ]]; then
  templates_dest="home/$templates_dest"
fi
for i in "${!targets[@]}"; do
  if [[ "${targets[i]}" != home/* ]]; then
    targets[i]="home/${targets[i]}"
  fi
done

# --- Validate bash version ---

if (( BASH_VERSINFO[0] < 4 )); then
  log_error "This script requires bash 4+. You have bash $BASH_VERSION."
  exit 1
fi

# --- Validate inputs ---

[[ -e "$src_path" ]] || { log_error "source_path does not exist: $src_path"; exit 2; }
is_file=0
src_basename=""
if [[ -f "$src_path" ]]; then
  is_file=1
  src_basename="$(basename "$src_path")"
elif [[ ! -d "$src_path" ]]; then
  log_error "source_path is neither a file nor a directory: $src_path"
  exit 2
fi

# Catch common mistake: running from wrong directory
if [[ "$templates_dest" == home/* ]]; then
  [[ -d "home" ]] || {
    log_error "'home/' directory not found. Run 'chezmoi cd' then re-run this script."
    exit 2
  }
fi

# --- Derive template prefix ---
# templates_dest = "home/.chezmoitemplates/neovim" => prefix = "neovim"
# templates_dest = ".chezmoitemplates/my/nested"   => prefix = "my/nested"
# We strip everything up to and including ".chezmoitemplates/".

templates_prefix="$templates_dest"
templates_prefix="${templates_prefix#home/}"
# Strip ".chezmoitemplates/" prefix (handles with or without leading path)
if [[ "$templates_prefix" == *".chezmoitemplates/"* ]]; then
  templates_prefix="${templates_prefix##*.chezmoitemplates/}"
elif [[ "$templates_prefix" == ".chezmoitemplates" ]]; then
  log_error "templates_dest_dir must include a subdirectory under .chezmoitemplates (e.g. .chezmoitemplates/neovim)"
  exit 2
fi

[[ -n "$templates_prefix" ]] || {
  log_error "Could not derive template prefix from templates_dest: $templates_dest"
  exit 2
}

log_verb "Derived template prefix: $templates_prefix"

# --- Dry-run banner ---

if (( dry_run )); then
  log_info "${BOLD}DRY RUN${RESET} — no files will be created or modified"
  echo
fi

# --- Copy source tree into .chezmoitemplates/<prefix> ---

log_info "Copying canonical content into: ${BOLD}$templates_dest${RESET}"

if (( ! dry_run )); then
  mkdir -p "$templates_dest"
  created_dirs+=("$templates_dest")
fi

if (( is_file )); then
  # For single file
  src_basename="$(basename "$src_path")"
  dest_file="$templates_dest/$src_basename"
  if (( dry_run )); then
    log_verb "Would copy $src_path to $dest_file"
  else
    cp "$src_path" "$dest_file"
  fi
else
  # For directory
  (
    cd "$src_path"

    # Build tar exclude args
    tar_excludes=()
    for pat in "${skip_patterns[@]}"; do
      tar_excludes+=("--exclude=$pat")
    done

    if (( dry_run )); then
      log_verb "Would copy from $src_path (excluding: ${skip_patterns[*]})"
    else
      # shellcheck disable=SC2068
      tar cf - "${tar_excludes[@]}" . \
        | (cd "$OLDPWD/$templates_dest" && tar xf -)
    fi
  )
fi

# --- Discover files to wrap ---

if (( dry_run )); then
  # In dry-run mode, enumerate from source (since dest wasn't populated)
  source_for_listing="$src_path"
else
  source_for_listing="$templates_dest"
fi

if (( is_file )); then
  # For single file
  if (( dry_run )); then
    rel_files=("$src_basename")
  else
    rel_files=("$src_basename")
  fi
else
  # For directory
  # Build find exclusions
  find_excludes=()
  for pat in "${skip_patterns[@]}"; do
    find_excludes+=(-path "./$pat" -prune -o)
  done

  mapfile -t rel_files < <(
    cd "$source_for_listing" && find . "${find_excludes[@]}" -type f -print | sed 's|^\./||' | sort
  )
fi

if [[ ${#rel_files[@]} -eq 0 ]]; then
  log_error "No files found after copy in: $templates_dest"
  exit 1
fi

log_verb "Found ${#rel_files[@]} file(s) to generate wrappers for"

# --- Generate wrapper templates ---

log_info "Generating wrapper templates in: ${BOLD}${targets[*]}${RESET}"

skipped_count=0
created_count=0
overwritten_count=0

create_wrapper_for_target() {
  local target_root="$1"
  local rel="$2"

  local wrapper_path="$target_root/$rel.tmpl"
  local wrapper_dir
  wrapper_dir="$(dirname "$wrapper_path")"

  # Template path uses forward slashes (Go template convention)
  local tpl_path="$templates_prefix/$rel"

  if [[ -e "$wrapper_path" && $force -ne 1 ]]; then
    log_verb "${YELLOW}SKIP${RESET} $wrapper_path (exists; use --force to overwrite)"
    (( skipped_count++ )) || true
    return 0
  fi

  if [[ -e "$wrapper_path" ]]; then
    log_verb "${YELLOW}OVERWRITE${RESET} $wrapper_path"
    (( overwritten_count++ )) || true
  else
    log_verb "${GREEN}CREATE${RESET} $wrapper_path"
    (( created_count++ )) || true
  fi

  if (( ! dry_run )); then
    mkdir -p "$wrapper_dir"
    cat > "$wrapper_path" <<TMPL
{{- template "$tpl_path" . -}}
TMPL
  fi
}

for t in "${targets[@]}"; do
  if (( ! dry_run )); then
    mkdir -p "$t"
    created_dirs+=("$t")
  fi
  for rel in "${rel_files[@]}"; do
    create_wrapper_for_target "$t" "$rel"
  done
done

# --- Summary ---

echo
log_ok "${BOLD}Done.${RESET}"
echo
echo "${BOLD}Summary:${RESET}"
echo "  Canonical templates: $templates_dest"
echo "  Template prefix:     $templates_prefix"
echo "  Source files:         ${#rel_files[@]}"
echo "  Wrappers created:    $created_count"
echo "  Wrappers overwritten: $overwritten_count"
echo "  Wrappers skipped:    $skipped_count"
echo "  Wrapper targets:"
for t in "${targets[@]}"; do
  echo "    - $t"
done
echo

if (( dry_run )); then
  echo "${BOLD}This was a dry run.${RESET} Re-run without --dry-run to apply."
else
  echo "${BOLD}Next steps:${RESET}"
  echo "  1) git status    — review new files"
  echo "  2) chezmoi diff  — see what would apply"
  echo "  3) chezmoi apply — deploy to your home directory"
fi