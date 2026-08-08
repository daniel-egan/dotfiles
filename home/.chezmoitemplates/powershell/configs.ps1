Set-PSReadLineOption -HistorySavePath (Join-Path $PSScriptRoot ".ps_history")
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 10000