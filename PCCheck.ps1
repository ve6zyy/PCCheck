<#
 PCCheck.ps1 - orchestrator (flat layout, enhanced)
#>
param(
    [ValidateSet("Full","Quick")]
    [string]$Mode = "Full"
)

$ErrorActionPreference = "Stop"
$installRoot = "C:\Temp\Scripts"
$dumpRoot    = "C:\Temp\Dump"
$logFile     = Join-Path $dumpRoot "pccheck.log"
Start-Transcript -Path $logFile -Force -ErrorAction SilentlyContinue

# Load cfg
$configPath = Join-Path $installRoot "cfg\cfg.json"
if (-not (Test-Path $configPath)) {
    Write-Warning "cfg.json missing; attempting remote fallback"
    $remote = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main/cfg/cfg.json"
    try { Invoke-WebRequest -Uri $remote -OutFile (Join-Path $installRoot "cfg.json") -UseBasicParsing -ErrorAction Stop; $configPath = Join-Path $installRoot "cfg.json" } catch {}
}
$configJson = $null
if (Test-Path $configPath) { try { $configJson = Get-Content $configPath -Raw | ConvertFrom-Json } catch {} }

# Ensure dump subfolders
New-Item -Path $dumpRoot -ItemType Directory -Force | Out-Null
$subs = @("MFT","AMCache","Events","Processes","Prefetch","Packers","Results")
foreach ($s in $subs) { New-Item -Path (Join-Path $dumpRoot $s) -ItemType Directory -Force | Out-Null }

# Module list
$moduleBase = $installRoot
if ($Mode -eq "Quick") { $modules = @("QuickMFT.ps1","Registry.ps1","SystemLogs.ps1") } else { $modules = @("MFT.ps1","Registry.ps1","SystemLogs.ps1","ProcDump.ps1","Packers.ps1") }

# Start modules as jobs
$jobs = @()
foreach ($m in $modules) {
    $mPath = Join-Path $moduleBase $m
    if (-not (Test-Path $mPath)) { Write-Warning "Missing module: $mPath"; continue }
    $jobs += Start-Job -ScriptBlock { param($p) & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p } -ArgumentList $mPath
    Start-Sleep -Milliseconds 200
}

# Wait with timeout
$timeout = 20*60
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($jobs.Count -gt 0 -and $sw.Elapsed.TotalSeconds -lt $timeout) {
    foreach ($j in @($jobs)) {
        $j | Receive-Job -ErrorAction SilentlyContinue | Out-Null
        if ($j.State -in @('Completed','Failed','Stopped')) {
            Remove-Job -Job $j -Force -ErrorAction SilentlyContinue
            $jobs = $jobs | Where-Object { $_.Id -ne $j.Id }
        }
    }
    Start-Sleep -Seconds 1
}
$sw.Stop()
if ($jobs.Count -gt 0) { Write-Warning "Some modules timed out; stopping them"; $jobs | ForEach-Object { Stop-Job -Job $_ -Force; Remove-Job -Job $_ -Force } }

# Simple aggregation & keyword scan
function SafeCsv($p){ if (Test-Path $p) { Import-Csv $p -ErrorAction SilentlyContinue } else { @() } }
$MFT = SafeCsv (Join-Path $dumpRoot "MFT\MFT.csv")
$AMC = SafeCsv (Join-Path $dumpRoot "AMCache\AmCache.csv")
$Events = SafeCsv (Join-Path $dumpRoot "Events\Events.csv")
$procFiles = Get-ChildItem -Path (Join-Path $dumpRoot "Processes") -Recurse -File -ErrorAction SilentlyContinue

$keywords = if ($configJson -and $configJson.Keywords) { $configJson.Keywords } else { @("aimbot","triggerbot","usbdeview","ro9an","abby","hitbox","clumsy","1337","skript","astra","leet","hydro") }

$results = @()
foreach ($k in $keywords) {
    $found = @()
    if ($MFT) { $found += $MFT | Where-Object { ($_ | Get-Member -Name FilePath -ErrorAction SilentlyContinue) -and ($_.FilePath -match [regex]::Escape($k)) } | ForEach-Object { $_.FilePath } }
    if ($AMC) { $found += $AMC | Where-Object { ($_ | Get-Member -Name FullPath -ErrorAction SilentlyContinue) -and ($_.FullPath -match [regex]::Escape($k)) } | ForEach-Object { $_.FullPath } }
    if ($Events) { $found += $Events | Where-Object { ($_ | Out-String) -match [regex]::Escape($k) } | ForEach-Object { ($_ | Out-String).Trim() } }
    foreach ($pf in $procFiles) {
        try { $c = Get-Content -Path $pf.FullName -ErrorAction SilentlyContinue; if ($c -and ($c -match [regex]::Escape($k))) { $found += "$($pf.FullName): matched" } } catch {}
    }
    if ($found.Count -gt 0) { $results += "=== Keyword: $k ==="; $results += ($found | Sort-Object -Unique); $results += "" }
}

$resultsFile = Join-Path $dumpRoot "Results\Results.txt"
if ($results.Count -gt 0) { $results | Out-File -FilePath $resultsFile -Encoding UTF8 } else { "No suspicious keywords found at $(Get-Date)" | Out-File -FilePath $resultsFile -Encoding UTF8 }

# copy to dump root for viewer
Copy-Item -Path $resultsFile -Destination (Join-Path $dumpRoot "Results.txt") -Force

# start viewer server
$localhost = Join-Path $installRoot "Localhost.ps1"
if (Test-Path $localhost) { Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$localhost`"" -WindowStyle Hidden; Start-Sleep -Seconds 1; Start-Process "http://localhost:8080/Viewer.html" } else { $v = Join-Path $dumpRoot "Viewer.html"; if (Test-Path $v) { Start-Process $v } }

Stop-Transcript
Write-Host "PCCheck completed. Results at $resultsFile"
