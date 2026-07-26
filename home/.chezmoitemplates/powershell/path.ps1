# Helper function (similar to NuShell's path add)
function Add-ToPath {
    param([string]$Directory)
    $Expanded = $Directory -replace '^~', $HOME
    if ((Test-Path $Expanded) -and ($env:PATH -notlike "*$Expanded*")) {
        $env:PATH = "$Expanded$([System.IO.Path]::PathSeparator)$env:PATH"
    }
}

Add-ToPath "/home/linuxbrew/.linuxbrew/bin"
Add-ToPath "~/bin"
Add-ToPath "~/.local/bin"