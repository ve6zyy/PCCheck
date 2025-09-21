# Menu.ps1 - Main entry point
$installDir = "C:\Temp\Scripts"
$toolsDir   = Join-Path $installDir "tools"
$dumpDir    = "C:\Temp\Dump"
$rawBase    = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main"

New-Item -Path $dumpDir -ItemType Directory -Force | Out-Null
New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null

function Download-Script($name) {
    $url = "$rawBase/$name"
    $out = Join-Path $installDir $name
    $outDir = Split-Path $out -Parent
    if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
}

# Scripts to fetch
$scripts = @(
    "PCCheck.ps1","Localhost.ps1","Viewer.html",
    "MFT.ps1","QuickMFT.ps1","Registry.ps1","SystemLogs.ps1","ProcDump.ps1","Packers.ps1",
    "cfg/cfg.json"
)

foreach ($s in $scripts) { Download-Script $s }

# Tools to fetch
$tools = @(
    @{Name="MFTECmd"; Url="https://github.com/EricZimmerman/MFTECmd/releases/latest/download/MFTECmd.zip"},
    @{Name="AmcacheParser"; Url="https://github.com/EricZimmerman/AmcacheParser/releases/latest/download/AmcacheParser.zip"},
    @{Name="SBECmd"; Url="https://github.com/EricZimmerman/SBECmd/releases/latest/download/SBECmd.zip"},
    @{Name="Strings"; Url="https://download.sysinternals.com/files/Strings.zip"}
)

foreach ($t in $tools) {
    $zip = Join-Path $toolsDir ($t.Name + ".zip")
    Invoke-WebRequest -Uri $t.Url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $toolsDir -Force
    Remove-Item $zip -Force
}

# Menu
function Show-Menu {
    Clear-Host
    Write-Host "=== PCCheck Menu ===" -ForegroundColor Cyan
    Write-Host "1. Full Scan"
    Write-Host "2. Quick Scan"
    Write-Host "3. Open Results Viewer"
    Write-Host "4. Exit"
    Write-Host ""
    $choice = Read-Host "Choose option"
    switch ($choice) {
        "1" { & (Join-Path $installDir "PCCheck.ps1") -Mode Full; Pause }
        "2" { & (Join-Path $installDir "PCCheck.ps1") -Mode Quick; Pause }
        "3" { Start-Process "http://localhost:8080/Viewer.html"; Pause }
        "4" { exit }
        default { Write-Host "Invalid choice"; Pause }
    }
    Show-Menu
}

Show-Menu
