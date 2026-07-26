# ls -la | sort-by type name -i
function ll {
    Get-ChildItem -Force | Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
}

# mkcd [newPath]
function mkcd {
    param(
        [Parameter(Mandatory=$true)]
        [string]$newPath
    )
    
    # Create the directory (-Force prevents errors if it already exists)
    New-Item -ItemType Directory -Path $newPath -Force | Out-Null
    
    # Change location to the new directory
    Set-Location -Path $newPath
}

# !! - Expand to last command (works with "sudo !!" too)
Set-PSReadLineKeyHandler -Chord "!" -ScriptBlock {
    param($key, $arg)
    
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
    # Check if previous character is '!'
    if ($cursor -gt 0 -and $line[$cursor - 1] -eq '!') {
        # Delete the previous '!' and insert last command
        [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar()
        $lastCommand = (Get-History -Count 1).CommandLine
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($lastCommand)
    } else {
        # Just insert a normal '!'
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('!')
    }
}