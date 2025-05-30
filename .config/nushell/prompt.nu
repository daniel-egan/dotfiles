# Transient prompt configuration - minimal prompt for previous commands
# Shows only the prompt character after command execution
$env.TRANSIENT_PROMPT_COMMAND = {|| "❯ " }

# Remove all indicators for transient prompts to keep them clean
$env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }

# Function to display command execution information (exit code and duration)
# This function will be used by both prompts
let get_execution_info = {||
    # Get the exit code of the last command, default to 0 if not set
    let exit_code = ($env.LAST_EXIT_CODE? | default 0)
    
    # Convert command duration from milliseconds to proper duration format
    let duration = if ($env.CMD_DURATION_MS? != null) {
        ($env.CMD_DURATION_MS | into int | $in * 1_000_000 | into duration)
    } else {
        null
    }
    
    # Display different information based on exit code and duration
    if ($exit_code != 0) and ($duration != null) {
        # Show both error code and duration in red
        $"(ansi red)Code: ($exit_code) after ($duration)(ansi reset)"
    } else if ($exit_code != 0) {
        # Show only error code in red
        $"(ansi red)Code: ($exit_code)(ansi reset)"
    } else if ($duration != null) {
        # Show only duration in green for successful commands
        $"(ansi green)($duration)(ansi reset)"
    } else {
        # Show nothing if no error and no duration info
        ""
    }
}

# Set the right side of transient prompt to show execution info
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = $get_execution_info

# Main prompt configuration - shows current directory and prompt character
$env.PROMPT_COMMAND = {|| 
    # Replace home path with ~ for cleaner display
    let dir = ($env.PWD | str replace $nu.home-path "~")
    # Display directory in blue on one line, prompt character on next line
    $"(ansi blue)($dir)(ansi reset)\n❯ "
}

# Show execution info on the active prompt too, then it transitions to transient
$env.PROMPT_COMMAND_RIGHT = $get_execution_info

# Remove all indicators for the main prompt to keep it clean
$env.PROMPT_INDICATOR = {|| "" }
$env.PROMPT_INDICATOR_VI_INSERT = {|| "" }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "" }

# Set multiline indicator for continuation lines
$env.PROMPT_MULTILINE_INDICATOR = {|| "  " }

# Disable the startup banner for a cleaner shell experience
$env.config.show_banner = false