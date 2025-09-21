# Registry.ps1 - Amcache & Shellbags via AmcacheParser & SBECmd (if available)
$dumpRoot = "C:\Temp\Dump"
$outDir = Join-Path $dumpRoot "AMCache"
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

$tools = "C:\Temp\Scripts\tools"
$am = Get-ChildItem -Path $tools -Filter "AmcacheParser.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$sbe = Get-ChildItem -Path $tools -Filter "SBECmd.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($am) {
    Write-Host "AmcacheParser found; extracting Amcache..."
    try { & $am.FullName -f "C:\Windows\AppCompat\Programs\Amcache.hve" --csv $outDir 2>$null } catch { Write-Warning "AmcacheParser failed: $_" }
} else { Write-Warning "AmcacheParser not found; skipping Amcache parsing." }

if ($sbe) {
    Write-Host "SBECmd found; exporting ShellBags..."
    try { & $sbe.FullName -d "$env:LocalAppData\Microsoft\Windows" --csv $outDir 2>$null } catch { Write-Warning "SBECmd failed: $_" }
} else { Write-Warning "SBECmd not found; skipping ShellBags." }

# Basic fallback: list installed programs
try {
    Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
        ForEach-Object { [PSCustomObject]@{Key=$_.PSChildName; DisplayName=(Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DisplayName } } |
        Export-Csv -Path (Join-Path $outDir "InstalledPrograms.csv") -NoTypeInformation -Encoding UTF8
} catch {}
