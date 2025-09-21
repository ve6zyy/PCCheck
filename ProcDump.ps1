$dump = "C:\Temp\Dump\Processes\Raw"; New-Item $dump -ItemType Directory -Force | Out-Null
Get-Process | Select-Object Id,ProcessName,StartTime | Export-Csv (Join-Path $dump "..\processes.csv") -NoTypeInformation
$strings = Get-ChildItem "C:\Temp\Scripts\tools" -Filter "strings*.exe" -Recurse | Select-Object -First 1
if ($strings) {
    foreach ($p in (Get-Process | Select-Object -First 5)) {
        & $strings.FullName -n 8 -pid $p.Id | Out-File (Join-Path $dump "p_$($p.Id).txt")
    }
}
