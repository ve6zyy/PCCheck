# installer.ps1 - PCCheck setup (rehosted, with tools)
# Run this as Administrator

$ErrorActionPreference = "Stop"

$installDir = "C:\Temp\Scripts"
$dumpDir    = "C:\Temp\Dump"
$toolsDir   = Join-Path $installDir "tools"

# Create folders
New-Item -Path $installDir -ItemType Directory -Force | Out-Null
New-Item -Path $dumpDir -ItemType Directory -Force | Out-Null
New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null

# Your GitHub raw base (adjust if you put scripts in subfolder)
$rawBase = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main"

# List of scripts to download
$scripts = @(
    "Menu.ps1","PCCheck.ps1","Localhost.ps1","Viewer.html",
    "MFT.ps1","QuickMFT.ps1","Registry.ps1","SystemLogs.ps1",
    "ProcDump.ps1","Packers.ps1","cfg/cfg.json"
)

Write-Host "[*] Downloading PCCheck scripts..."
foreach ($s in $scripts) {
    $url = "$rawBase/$s"
    $outFile = Join-Path $installDir $s
    $outDir = Split-Path $outFile -Parent
    if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
    Write-Host "  [+] $s"
}

# Download tools from official sources
$toolSources = @(
    @{ Name="MFTECmd"; Url="https://github.com/EricZimmerman/MFTECmd/releases/latest/download/MFTECmd.zip" },
    @{ Name="AmcacheParser"; Url="https://github.com/EricZimmerman/AmcacheParser/releases/latest/download/AmcacheParser.zip" },
    @{ Name="SBECmd"; Url="https://github.com/EricZimmerman/SBECmd/releases/latest/download/SBECmd.zip" },
    @{ Name="Strings"; Url="https://download.sysinternals.com/files/Strings.zip" }
)

Write-Host "[*] Downloading forensic tools..."
foreach ($t in $toolSources) {
    $zipPath = Join-Path $toolsDir ("$($t.Name).zip")
    Invoke-WebRequest -Uri $t.Url -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $toolsDir -Force
    Remove-Item $zipPath -Force
    Write-Host "  [+] $($t.Name)"
}

# Normalize tool exe placement
Get-ChildItem -Path $toolsDir -Recurse -File -Include *.exe | ForEach-Object {
    $dest = Join-Path $toolsDir $_.Name
    if ($_.FullName -ne $dest) { Copy-Item -Path $_.FullName -Destination $dest -Force }
}

# Set execution policies
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force

# Defender exclusion
try {
    Add-MpPreference -ExclusionPath "C:\Temp" | Out-Null
    Write-Host "[+] Added Defender exclusion for C:\Temp"
} catch { Write-Warning "Could not add Defender exclusion." }

# Copy Viewer to Dump (so Localhost serves it)
Copy-Item -Path (Join-Path $installDir "Viewer.html") -Destination (Join-Path $dumpDir "Viewer.html") -Force

# Launch menu
$menu = Join-Path $installDir "Menu.ps1"
if (Test-Path $menu) {
    Write-Host "[*] Launching PCCheck menu..."
    & $menu
} else {
    Write-Warning "Menu.ps1 not found!"
}
