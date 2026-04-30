#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
CHEZMOI_SOURCE_DIR=""
TEMPLATES_DIR=""

# --- Utility Functions ---

die() {
    printf '\033[31mError: %s\033[0m\n' "$1" >&2
    exit 1
}

info() {
    printf '\033[36m>> %s\033[0m\n' "$1"
}

success() {
    printf '\033[32m✓ %s\033[0m\n' "$1"
}

prompt() {
    printf '\033[33m%s\033[0m ' "$1"
}

# --- Core Functions ---

detect_source_dir() {
    # Walk up from script location or cwd to find home/.chezmoiroot
    local dir
    dir="$(pwd)"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/home/.chezmoiroot" ]]; then
            CHEZMOI_SOURCE_DIR="$dir/home"
            TEMPLATES_DIR="$dir/home/.chezmoitemplates"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    die "Could not find home/.chezmoiroot in any parent directory. Run this from within your chezmoi repo."
}

# Convert a real target path like ~/.config/nushell/config.nu or %APPDATA%/nushell/config.nu
# into chezmoi source path like dot_config/nushell/config.nu
target_to_chezmoi_path() {
    local target="$1"

    # Normalize: expand ~ and common variables for path conversion
    # Strip leading path prefixes to get the relative portion after the "root"
    local rel_path="$target"

    # Handle ~/.config/... -> dot_config/...
    if [[ "$rel_path" =~ ^~/.config/(.*) ]]; then
        rel_path="dot_config/${BASH_REMATCH[1]}"
    elif [[ "$rel_path" =~ ^\$\{XDG_CONFIG_HOME:-~/.config\}/(.*) ]]; then
        rel_path="dot_config/${BASH_REMATCH[1]}"
    elif [[ "$rel_path" =~ ^XDG_CONFIG_HOME/(.*) ]]; then
        rel_path="dot_config/${BASH_REMATCH[1]}"
    elif [[ "$rel_path" =~ ^~/(.*) ]]; then
        # Generic dotfile handling: ~/.foo -> dot_foo
        local after="${BASH_REMATCH[1]}"
        # Split into first component and rest
        local first rest
        first="$(echo "$after" | cut -d'/' -f1)"
        rest="$(echo "$after" | cut -d'/' -f2- -s)"
        if [[ "$first" == .* ]]; then
            first="dot_${first#.}"
        fi
        if [[ -n "$rest" ]]; then
            rel_path="${first}/${rest}"
        else
            rel_path="${first}"
        fi
    elif [[ "$rel_path" =~ ^%APPDATA%[/\\](.*) ]]; then
        rel_path="AppData/Roaming/${BASH_REMATCH[1]}"
    elif [[ "$rel_path" =~ ^%LOCALAPPDATA%[/\\](.*) ]]; then
        rel_path="AppData/Local/${BASH_REMATCH[1]}"
    elif [[ "$rel_path" =~ ^%USERPROFILE%[/\\](.*) ]]; then
        local after="${BASH_REMATCH[1]}"
        local first rest
        first="$(echo "$after" | cut -d'/' -f1)"
        rest="$(echo "$after" | cut -d'/' -f2- -s)"
        if [[ "$first" == .* ]]; then
            first="dot_${first#.}"
        fi
        if [[ -n "$rest" ]]; then
            rel_path="${first}/${rest}"
        else
            rel_path="${first}"
        fi
    else
        # If we can't parse it, just use it as-is (user gives relative chezmoi path)
        rel_path="$target"
    fi

    # Normalize backslashes to forward slashes
    rel_path="${rel_path//\\//}"

    echo "$rel_path"
}

# Adds .tmpl extension to the chezmoi source path
make_tmpl_path() {
    echo "${1}.tmpl"
}

# Get a template name from a file path, used for {{ template "name" . }}
# For single files: just the filename
# For directories: dirname/filename to keep them organized
make_template_name() {
    local group_name="$1"  # empty for single file, dirname for directory mode
    local filename="$2"

    if [[ -n "$group_name" ]]; then
        echo "${group_name}/${filename}"
    else
        echo "$filename"
    fi
}

collect_destinations() {
    local destinations=()
    info "Enter destination paths where this should be managed by chezmoi."
    info "Examples:"
    echo "  ~/.config/topgrade/topgrade.toml"
    echo "  %APPDATA%/topgrade/topgrade.toml"
    echo "  ~/.config/nushell   (for directories)"
    echo ""
    info "Enter one path per line. Empty line when done."
    echo ""

    while true; do
        prompt "Destination:"
        local dest
        read -r dest
        [[ -z "$dest" ]] && break
        destinations+=("$dest")
    done

    if [[ ${#destinations[@]} -eq 0 ]]; then
        die "At least one destination is required."
    fi

    printf '%s\n' "${destinations[@]}"
}

process_single_file() {
    local source_file="$1"
    shift
    local destinations=("$@")

    local filename
    filename="$(basename "$source_file")"

    # Copy to .chezmoitemplates
    local template_name="$filename"
    local template_dest="${TEMPLATES_DIR}/${template_name}"

    mkdir -p "$(dirname "$template_dest")"
    cp "$source_file" "$template_dest"
    success "Template created: .chezmoitemplates/${template_name}"

    # Create chezmoi source files for each destination
    for dest in "${destinations[@]}"; do
        local chezmoi_rel
        chezmoi_rel="$(target_to_chezmoi_path "$dest")"
        local tmpl_file
        tmpl_file="$(make_tmpl_path "$chezmoi_rel")"
        local full_path="${CHEZMOI_SOURCE_DIR}/${tmpl_file}"

        mkdir -p "$(dirname "$full_path")"
        echo "{{ template \"${template_name}\" . }}" > "$full_path"
        success "Source file created: home/${tmpl_file}"
    done
}

process_directory() {
    local source_dir="$1"
    shift
    local destinations=("$@")

    # Use the directory basename as group name in templates
    local group_name
    group_name="$(basename "$source_dir")"

    # Find all files in the directory
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$source_dir" -type f -print0)

    if [[ ${#files[@]} -eq 0 ]]; then
        die "No files found in directory: $source_dir"
    fi

    info "Found ${#files[@]} file(s) in ${source_dir}:"
    for f in "${files[@]}"; do
        echo "  $(realpath --relative-to="$source_dir" "$f" 2>/dev/null || echo "$f")"
    done
    echo ""

    for file in "${files[@]}"; do
        # Get path relative to the source directory
        local rel_file
        rel_file="$(realpath --relative-to="$source_dir" "$file" 2>/dev/null)"
        if [[ -z "$rel_file" ]]; then
            # Fallback for systems without realpath --relative-to
            rel_file="${file#${source_dir}/}"
        fi

        local template_name="${group_name}/${rel_file}"
        local template_dest="${TEMPLATES_DIR}/${template_name}"

        # Copy to .chezmoitemplates/groupname/...
        mkdir -p "$(dirname "$template_dest")"
        cp "$file" "$template_dest"
        success "Template: .chezmoitemplates/${template_name}"

        # Create chezmoi source files at each destination
        for dest in "${destinations[@]}"; do
            # For directories, the destination is the parent dir.
            # Append the relative file path to it.
            local full_dest="${dest%/}/${rel_file}"
            local chezmoi_rel
            chezmoi_rel="$(target_to_chezmoi_path "$full_dest")"
            local tmpl_file
            tmpl_file="$(make_tmpl_path "$chezmoi_rel")"
            local full_path="${CHEZMOI_SOURCE_DIR}/${tmpl_file}"

            mkdir -p "$(dirname "$full_path")"
            echo "{{ template \"${template_name}\" . }}" > "$full_path"
            success "Source: home/${tmpl_file}"
        done
    done
}

usage() {
    cat <<'EOF'
chezmoi-template-helper: Create chezmoi template files from configs

Usage:
  ./chezmoi-template.sh <file-or-directory>
  ./chezmoi-template.sh                      (interactive mode)

This script will:
  1. Copy your config file(s) into home/.chezmoitemplates/
  2. Ask where the config lives on your target systems
  3. Create chezmoi .tmpl source files that reference the template

Examples:
  ./chezmoi-template.sh ~/.config/topgrade/topgrade.toml
  ./chezmoi-template.sh ~/.config/nushell/
EOF
}

main() {
    detect_source_dir
    info "Chezmoi source dir: ${CHEZMOI_SOURCE_DIR}"
    info "Templates dir: ${TEMPLATES_DIR}"
    echo ""

    local input_path=""

    if [[ $# -ge 1 ]]; then
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            usage
            exit 0
        fi
        input_path="$1"
    else
        prompt "Path to file or directory to templatize:"
        read -r input_path
    fi

    # Expand ~ if present
    input_path="${input_path/#\~/$HOME}"

    if [[ ! -e "$input_path" ]]; then
        die "Path does not exist: $input_path"
    fi

    echo ""

    # Collect destinations
    local destinations=()
    while IFS= read -r line; do
        destinations+=("$line")
    done < <(collect_destinations)

    echo ""
    info "Summary:"
    echo "  Input: $input_path"
    echo "  Destinations:"
    for d in "${destinations[@]}"; do
        echo "    - $d"
    done
    echo ""

    prompt "Proceed? [Y/n]:"
    local confirm
    read -r confirm
    confirm="${confirm:-Y}"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        die "Aborted."
    fi

    echo ""
    mkdir -p "$TEMPLATES_DIR"

    if [[ -f "$input_path" ]]; then
        process_single_file "$input_path" "${destinations[@]}"
    elif [[ -d "$input_path" ]]; then
        process_directory "$input_path" "${destinations[@]}"
    else
        die "Input is neither a file nor a directory: $input_path"
    fi

    echo ""
    success "Done! Review the generated files and adjust templates as needed."
    info "You can now add chezmoi template logic ({{ if eq .chezmoi.os ... }}) to files in .chezmoitemplates/"
}

main "$@"