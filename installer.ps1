# installer.ps1 - PCCheck bootstrap installer
# Run as Administrator

$ErrorActionPreference = "Stop"

$installDir = "C:\Temp\Scripts"
$dumpDir    = "C:\Temp\Dump"
$toolsDir   = Join-Path $installDir "tools"

# Create folders
New-Item -Path $installDir -ItemType Directory -Force | Out-Null
New-Item -Path $dumpDir -ItemType Directory -Force | Out-Null
New-Item -Path $toolsDir -ItemType Directory -Force | Out-Null

# Repo base URL
$rawBase = "https://raw.githubusercontent.com/ve6zyy/PCCheck/main"

# Download only Menu.ps1 like the old one did
Invoke-WebRequest -Uri "$rawBase/Menu.ps1" -OutFile (Join-Path $installDir "Menu.ps1") -UseBasicParsing

# Allow scripts to run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned -Force

# Defender exclusion
try { Add-MpPreference -ExclusionPath "C:\Temp" | Out-Null } catch {}

# Launch menu
& (Join-Path $installDir "Menu.ps1")
