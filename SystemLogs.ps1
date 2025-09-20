# SystemLogs.ps1 - basic event log exports
$dumpRoot = "C:\Temp\Dump"
$eventsDir = Join-Path $dumpRoot "Events"
New-Item -Path $eventsDir -ItemType Directory -Force | Out-Null

# Export Security, System, Application recent events (small sample each)
$categories = @("System","Application","Security")
foreach ($c in $categories) {
    try {
        $out = Join-Path $eventsDir ("Events_" + $c + ".csv")
        Get-WinEvent -LogName $c -MaxEvents 200 | Select-Object TimeCreated,Id,LevelDisplayName,ProviderName,Message | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    } catch {}
}

# Example: export Defender operational log if present
try {
    Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 1000 | Select-Object TimeCreated,Id,LevelDisplayName,Message | Export-Csv -Path (Join-Path $eventsDir "Defender.csv") -NoTypeInformation -Encoding UTF8
} catch {}
