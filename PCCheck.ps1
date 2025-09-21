param([ValidateSet("Full","Quick")][string]$Mode="Full")

$ErrorActionPreference = "Stop"
$installDir = "C:\Temp\Scripts"
$dumpDir    = "C:\Temp\Dump"

Start-Transcript -Path (Join-Path $dumpDir "pccheck.log") -Force

$config = Get-Content (Join-Path $installDir "cfg\cfg.json") -Raw | ConvertFrom-Json
$keywords = $config.Keywords

$modules = if ($Mode -eq "Quick") {
    @("QuickMFT.ps1","Registry.ps1","SystemLogs.ps1")
} else {
    @("MFT.ps1","Registry.ps1","SystemLogs.ps1","ProcDump.ps1","Packers.ps1")
}

$jobs = foreach ($m in $modules) {
    $path = Join-Path $installDir $m
    Start-Job -ScriptBlock { param($p) & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p } -ArgumentList $path
}

Wait-Job -Job $jobs -Timeout 1200 | Out-Null
Receive-Job -Job $jobs -ErrorAction SilentlyContinue | Out-Null
Remove-Job -Job $jobs -Force

# Collect logs
$results = @()
foreach ($k in $keywords) {
    $hits = Select-String -Path "$dumpDir\**\*.csv","$dumpDir\**\*.txt" -Pattern $k -ErrorAction SilentlyContinue
    if ($hits) {
        $results += "=== Keyword: $k ==="
        $results += ($hits | ForEach-Object { "$($_.Path):$($_.Line)" })
        $results += ""
    }
}

$resultsFile = Join-Path $dumpDir "Results.txt"
if ($results) { $results | Out-File $resultsFile -Encoding UTF8 } else { "No matches" | Out-File $resultsFile }

Copy-Item (Join-Path $installDir "Viewer.html") -Destination (Join-Path $dumpDir "Viewer.html") -Force

& (Join-Path $installDir "Localhost.ps1")

Stop-Transcript
