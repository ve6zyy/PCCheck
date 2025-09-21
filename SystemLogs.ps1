$dump = "C:\Temp\Dump\Events"; New-Item $dump -ItemType Directory -Force | Out-Null
Get-WinEvent -LogName System -MaxEvents 500 | Export-Csv (Join-Path $dump "System.csv") -NoTypeInformation
Get-WinEvent -LogName Application -MaxEvents 500 | Export-Csv (Join-Path $dump "Application.csv") -NoTypeInformation
Get-WinEvent -LogName Security -MaxEvents 500 | Export-Csv (Join-Path $dump "Security.csv") -NoTypeInformation
