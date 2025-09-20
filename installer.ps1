# installer.ps1
# Bootstrap script - must be run as Administrator
[CmdletBinding()]
param()

function Test-IsAdmin {
    $current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Error "This installer must be run as Administrator. Right-click -> Run as Administrator."
    exit 1
}

# raw base pointing to your repo (ve6zyy/PCCheck)
$rawBase = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main"

# Files to fetch (flat layout; cfg stays in cfg/)
$files = @(
    "Menu.ps1",
    "PCCheck.ps1",
    "Localhost.ps1",
    "Viewer.html",
    "README.md",
    "cfg/cfg.json",
    "MFT.ps1",
    "QuickMFT.ps1",
    "Registry.ps1",
    "SystemLogs.ps1",
    "ProcDump.ps1",
    "Packers.ps1"
)

$destination = "C:\Temp\Scripts"
$dump = "C:\Temp\Dump"

# Prepare directories
New-Item -Path $destination -ItemType Directory -Force | Out-Null
New-Item -Path $dump -ItemType Directory -Force | Out-Null

function Download-RawFile {
    param($relPath)
    $url = "$rawBase/$relPath"
    $outFull = Join-Path -Path $destination -ChildPath $relPath
    $outDir = Split-Path $outFull -Parent
    if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    Write-Host "Downloading $relPath ..."
    for ($i=0; $i -lt 3; $i++) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $outFull -UseBasicParsing -ErrorAction Stop
            Write-Host "Saved $outFull"
            return $true
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    Write-Warning "Failed to download $relPath from $url"
    return $false
}

foreach ($f in $files) {
    Download-RawFile -relPath $f
}

# Copy Viewer.html into dump root so Localhost can serve it from the dump folder
$viewerSrc = Join-Path $destination "Viewer.html"
if (Test-Path $viewerSrc) {
    Copy-Item -Path $viewerSrc -Destination (Join-Path $dump "Viewer.html") -Force
}

# Ensure process-level policy to run downloaded scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Launch menu (run the local copy)
$menuPath = Join-Path $destination "Menu.ps1"
if (Test-Path $menuPath) {
    Write-Host "Launching Menu..."
    & $menuPath
} else {
    Write-Warning "Menu.ps1 not found at $menuPath"
}
