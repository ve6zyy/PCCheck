# SystemLogs.ps1 - export event logs
$dumpRoot = "C:\Temp\Dump"
$outDir = Join-Path $dumpRoot "Events"
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

$logs = @("System","Application","Security")
foreach ($l in $logs) {
    try { Get-WinEvent -LogName $l -MaxEvents 500 | Select-Object TimeCreated,Id,LevelDisplayName,ProviderName,Message | Export-Csv -Path (Join-Path $outDir ("Events_" + $l + ".csv")) -NoTypeInformation -Encoding UTF8 } catch { Write-Warning "Failed export $l: $_" }
}

# Defender operational log if present
try { Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 1000 | Select-Object TimeCreated,Id,Message | Export-Csv -Path (Join-Path $outDir "Defender.csv") -NoTypeInformation -Encoding UTF8 } catch {}
