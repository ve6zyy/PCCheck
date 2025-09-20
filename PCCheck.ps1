<#
 PCCheck.ps1 - orchestrator (flat script layout)
 param -Mode [Full|Quick]
#>
param(
    [ValidateSet("Full","Quick")]
    [string]$Mode = "Full"
)

$ErrorActionPreference = "Stop"
$installRoot = "C:\Temp\Scripts"
$dumpRoot = "C:\Temp\Dump"
$configPath = Join-Path $installRoot "cfg\cfg.json"

if (-not (Test-Path $configPath)) {
    Write-Warning "cfg.json not found locally. Attempting remote fallback..."
    $remoteCfg = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main/cfg/cfg.json"
    try {
        Invoke-WebRequest -Uri $remoteCfg -OutFile (Join-Path $installRoot "cfg.json") -UseBasicParsing -ErrorAction Stop
        $configPath = Join-Path $installRoot "cfg.json"
    } catch {
        Write-Warning "Remote cfg fetch failed. Using built-in defaults."
    }
}

$configJson = $null
if (Test-Path $configPath) {
    try { $configJson = Get-Content $configPath -Raw | ConvertFrom-Json } catch { $configJson = $null }
}

# ensure dump subfolders exist
New-Item -Path $dumpRoot -ItemType Directory -Force | Out-Null
$pathsToEnsure = @("MFT","AMCache","Events","Processes","Prefetch","Results")
foreach ($p in $pathsToEnsure) {
    New-Item -Path (Join-Path $dumpRoot $p) -ItemType Directory -Force | Out-Null
}

# modules selection (flat)
$moduleBase = $installRoot
if ($Mode -eq "Quick") {
    $modules = @("QuickMFT.ps1","Registry.ps1","SystemLogs.ps1")
} else {
    $modules = @("MFT.ps1","Registry.ps1","SystemLogs.ps1","ProcDump.ps1")
}

# start modules as background jobs
$jobs = @()
foreach ($m in $modules) {
    $mPath = Join-Path $moduleBase $m
    if (-not (Test-Path $mPath)) {
        Write-Warning "Module missing: $mPath"
        continue
    }
    $jobs += Start-Job -ScriptBlock {
        param($scriptPath)
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
    } -ArgumentList $mPath
    Start-Sleep -Milliseconds 200
}

# Wait for jobs (bounded wait)
$timeoutSeconds = 20 * 60
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($jobs.Count -gt 0 -and $sw.Elapsed.TotalSeconds -lt $timeoutSeconds) {
    foreach ($j in $jobs.ToArray()) {
        $j | Receive-Job -ErrorAction SilentlyContinue | Out-Null
        if ($j.State -in @('Completed','Failed','Stopped')) {
            Remove-Job -Job $j -Force -ErrorAction SilentlyContinue
            $jobs = $jobs | Where-Object { $_.Id -ne $j.Id }
        }
    }
    Start-Sleep -Seconds 1
}
$sw.Stop()

# Load CSV/text outputs for keyword scanning
function Safe-ImportCsv($path) { if (Test-Path $path) { Import-Csv $path -ErrorAction SilentlyContinue } else { @() } }

$MFTcsv = Safe-ImportCsv -path (Join-Path $dumpRoot "MFT\MFT.csv")
$AMCachecsv = Safe-ImportCsv -path (Join-Path $dumpRoot "AMCache\AmCache.csv")
$EventsCsv = Safe-ImportCsv -path (Join-Path $dumpRoot "Events\Events.csv")
$ProcessFiles = Get-ChildItem -Path (Join-Path $dumpRoot "Processes\Raw") -File -ErrorAction SilentlyContinue

# keywords
if ($configJson -and $configJson.Keywords) { $keywords = $configJson.Keywords } else {
    $keywords = @("aimbot","triggerbot","usbdeview","ro9an","abby","hitbox","clumsy","1337","skript","astra","leet","hydro")
}

$results = @()
foreach ($k in $keywords) {
    $found = @()
    if ($MFTcsv) { $found += $MFTcsv | Where-Object { ($_ | Get-Member -Name FilePath -MemberType NoteProperty -ErrorAction SilentlyContinue) -and ($_.FilePath -match [regex]::Escape($k)) } | ForEach-Object { $_.FilePath } }
    if ($AMCachecsv) { $found += $AMCachecsv | Where-Object { ($_ | Get-Member -Name FullPath -MemberType NoteProperty -ErrorAction SilentlyContinue) -and ($_.FullPath -match [regex]::Escape($k)) } | ForEach-Object { $_.FullPath } }
    if ($EventsCsv) { $found += $EventsCsv | Where-Object { ($_ | Out-String) -match [regex]::Escape($k) } | ForEach-Object { ($_ | Out-String).Trim() } }
    foreach ($pf in $ProcessFiles) {
        try {
            $content = Get-Content -Path $pf.FullName -ErrorAction SilentlyContinue
            if ($content -and ($content -match [regex]::Escape($k))) { $found += "$($pf.Name): matched in file" }
        } catch {}
    }
    if ($found.Count -gt 0) {
        $results += "=== Keyword: $k ==="
        $results += ($found | Sort-Object -Unique)
        $results += ""
    }
}

$resultsFile = Join-Path $dumpRoot "Results\Results.txt"
if ($results.Count -gt 0) {
    $results | Out-File -FilePath $resultsFile -Encoding UTF8
} else {
    "No suspicious keywords found (simple keyword scan) at $(Get-Date)" | Out-File -FilePath $resultsFile -Encoding UTF8
}

Write-Host "Results written to $resultsFile"

# copy results into dump root for viewer
Copy-Item -Path $resultsFile -Destination (Join-Path $dumpRoot "Results.txt") -Force

# Launch local viewer via Localhost service if available
$localHostScript = Join-Path $installRoot "Localhost.ps1"
if (Test-Path $localHostScript) {
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$localHostScript`"" -WindowStyle Hidden
    Start-Sleep -Seconds 1
    Start-Process "http://localhost:8080/Viewer.html"
} else {
    # fallback: open local file if viewer exists in dump
    $viewerLocal = Join-Path $dumpRoot "Viewer.html"
    if (Test-Path $viewerLocal) { Start-Process $viewerLocal }
}
