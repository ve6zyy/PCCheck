# ProcDump.ps1 - process listing and strings extraction (if strings.exe present)
$dumpRoot = "C:\Temp\Dump"
$outDir = Join-Path $dumpRoot "Processes"
New-Item -Path $outDir -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $outDir "Raw") -ItemType Directory -Force | Out-Null

try {
    Get-Process | Select-Object Id,ProcessName,@{Name="StartTime";Expression={($_.StartTime -as [string])}} | Export-Csv -Path (Join-Path $outDir "Raw\processes.csv") -NoTypeInformation -Encoding UTF8
} catch {}

$tools = "C:\Temp\Scripts\tools"
$strings = Get-ChildItem -Path $tools -Filter "strings.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $strings) { $strings = Get-ChildItem -Path $tools -Filter "strings64.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 }

if ($strings) {
    Write-Host "Strings found; extracting top processes..."
    $pids = Get-Process | Select-Object -First 5 -ExpandProperty Id -ErrorAction SilentlyContinue
    foreach ($pid in $pids) {
        try { & $strings.FullName -n 8 -pid $pid | Out-File -FilePath (Join-Path $outDir ("Raw\p_$pid.txt")) -Encoding UTF8 } catch {}
    }
} else {
    Write-Warning "strings.exe not found; skipping memory string extraction."
}
