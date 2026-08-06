Set-PSReadLineOption -HistorySavePath (Join-Path $PSScriptRoot ".ps_history")
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaxHistoryCount 10000