# installer.ps1 - enhanced installer (downloads scripts + forensic tools)
# Run as Administrator
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$rawBase    = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main"
$destination = "C:\Temp\Scripts"
$dump        = "C:\Temp\Dump"
$toolsDir    = Join-Path $destination "tools"

# Prepare folders
New-Item -Path $destination -ItemType Directory -Force | Out-Null
New-Item -Path $dump -ItemType Directory -Force | Out-Null
New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null

$log = Join-Path $dump "installer.log"
"Installer started at $(Get-Date -Format u)" | Out-File -FilePath $log -Encoding UTF8

function Log($m) {
    $t = "$(Get-Date -Format u) - $m"
    Write-Host $t
    Add-Content -Path $log -Value $t
}

# Download helper with retries
function Download-File($url,$out) {
    for ($i=0; $i -lt 4; $i++) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
            return $true
        } catch {
            Start-Sleep -Seconds (2 * ($i+1))
        }
    }
    return $false
}

# List of repo files to fetch (flat layout)
$scripts = @(
  "Menu.ps1","PCCheck.ps1","Localhost.ps1","Viewer.html","README.md",
  "MFT.ps1","QuickMFT.ps1","Registry.ps1","SystemLogs.ps1","ProcDump.ps1","Packers.ps1",
  "cfg/cfg.json"
)

foreach ($s in $scripts) {
    $url = "$rawBase/$s"
    $out = Join-Path $destination $s
    $outDir = Split-Path $out -Parent
    if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    Log "Downloading $s from $url"
    if (Download-File -url $url -out $out) {
        Log "Saved $out"
    } else {
        Log "Failed to download $url"
    }
}

# Third-party tools to download (official release direct links)
$toolDownloads = @(
    @{Name="MFTECmd"; ZipUrl="https://github.com/EricZimmerman/MFTECmd/releases/latest/download/MFTECmd.zip"},
    @{Name="AmcacheParser"; ZipUrl="https://github.com/EricZimmerman/AmcacheParser/releases/latest/download/AmcacheParser.zip"},
    @{Name="SBECmd"; ZipUrl="https://github.com/EricZimmerman/SBECmd/releases/latest/download/SBECmd.zip"},
    @{Name="Strings"; ZipUrl="https://download.sysinternals.com/files/Strings.zip"}
)

foreach ($t in $toolDownloads) {
    $name = $t.Name
    $zipOut = Join-Path $toolsDir ("$name.zip")
    Log "Downloading $name from $($t.ZipUrl)"
    if (Download-File -url $t.ZipUrl -out $zipOut) {
        try {
            Expand-Archive -Path $zipOut -DestinationPath $toolsDir -Force
            Remove-Item -Path $zipOut -Force -ErrorAction SilentlyContinue
            Log "Extracted $name to $toolsDir"
        } catch {
            Log "Failed to extract $zipOut - $_"
        }
    } else {
        Log "Failed to download $($t.ZipUrl)"
    }
}

# Normalize tool names: find exes and move top-level exes into toolsDir
Get-ChildItem -Path $toolsDir -Recurse -File -Include *.exe,*.bat -ErrorAction SilentlyContinue | ForEach-Object {
    $dest = Join-Path $toolsDir $_.Name
    if ($_.FullName -ne $dest) {
        try { Copy-Item -Path $_.FullName -Destination $dest -Force; Log "Copied $($_.FullName) -> $dest" } catch {}
    }
}

# Set execution policy for this process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
# Optionally set machine policy if user chooses (commented out for safety)
# Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force

# Add Defender exclusion for C:\Temp (best effort, may require admin)
try {
    Add-MpPreference -ExclusionPath "C:\Temp" -ErrorAction Stop
    Log "Added Windows Defender exclusion for C:\Temp"
} catch {
    Log "Could not add Defender exclusion (may already exist or policy restricts it)."
}

# Copy Viewer.html to dump root so Localhost can serve from dump
$viewerSrc = Join-Path $destination "Viewer.html"
if (Test-Path $viewerSrc) {
    Copy-Item -Path $viewerSrc -Destination (Join-Path $dump "Viewer.html") -Force
    Log "Copied Viewer.html to $dump"
}

# Launch menu
$menu = Join-Path $destination "Menu.ps1"
if (Test-Path $menu) {
    Log "Launching Menu"
    & $menu
} else {
    Log "Menu.ps1 not found at $menu"
}
"Installer finished at $(Get-Date -Format u)" | Out-File -FilePath $log -Append -Encoding UTF8
