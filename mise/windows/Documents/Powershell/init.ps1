# Initialize Zoxide
Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })

# Mise-en-place
(&mise activate pwsh) | Out-String | Invoke-Expression