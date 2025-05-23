$env.TRANSIENT_PROMPT_COMMAND = {|| "❯ " }
$env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }

# This function will be used by both prompts
let get_execution_info = {||
    let exit_code = ($env.LAST_EXIT_CODE? | default 0)
    let duration = if ($env.CMD_DURATION_MS? != null) {
        ($env.CMD_DURATION_MS | into int | $in * 1_000_000 | into duration)
    } else {
        null
    }
    
    if ($exit_code != 0) and ($duration != null) {
        $"(ansi red)Code: ($exit_code) after ($duration)(ansi reset)"
    } else if ($exit_code != 0) {
        $"(ansi red)Code: ($exit_code)(ansi reset)"
    } else if ($duration != null) {
        $"(ansi green)($duration)(ansi reset)"
    } else {
        ""
    }
}

$env.TRANSIENT_PROMPT_COMMAND_RIGHT = $get_execution_info

$env.PROMPT_COMMAND = {|| 
    let dir = ($env.PWD | str replace $nu.home-path "~")
    $"(ansi blue)($dir)(ansi reset)\n❯ "
}

# Show execution info on the active prompt too, then it transitions to transient
$env.PROMPT_COMMAND_RIGHT = $get_execution_info
$env.PROMPT_INDICATOR = {|| "" }
$env.PROMPT_INDICATOR_VI_INSERT = {|| "" }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "" }
$env.PROMPT_MULTILINE_INDICATOR = {|| "  " }

$env.config.show_banner = false