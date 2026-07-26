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