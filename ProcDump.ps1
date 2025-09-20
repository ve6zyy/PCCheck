# ProcDump.ps1 - process listing and strings extraction skeleton
$dumpRoot = "C:\Temp\Dump"
$procDir = Join-Path $dumpRoot "Processes"
New-Item -Path $procDir -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $procDir "Raw") -ItemType Directory -Force | Out-Null

# Basic process list
try {
    Get-Process | Select-Object Id, ProcessName, @{Name='StartTime';Expression={($_.StartTime -as [string]) -replace '\.',''}} -ErrorAction SilentlyContinue |
        Export-Csv -Path (Join-Path $procDir "Raw\processes.csv") -NoTypeInformation -Encoding UTF8
} catch {}

# Attempt to run strings extraction if strings.exe or strings2.exe is included in tools
$stringsCandidates = @("C:\Temp\Scripts\tools\strings2.exe","C:\Temp\Scripts\tools\strings.exe")
$stringsExe = $stringsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($stringsExe) {
    $pids = Get-Process | Select-Object -First 5 -ExpandProperty Id -ErrorAction SilentlyContinue
    foreach ($pid in $pids) {
        try {
            & $stringsExe -n 5 -pid $pid | Out-File -FilePath (Join-Path $procDir ("Raw\p_" + $pid + ".txt")) -Encoding UTF8
        } catch {}
    }
}
