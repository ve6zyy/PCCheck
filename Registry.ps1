# Registry.ps1 - AMCache & Shellbags skeleton (flat layout)
$dumpRoot = "C:\Temp\Dump"
$amacDir = Join-Path $dumpRoot "AMCache"
New-Item -Path $amacDir -ItemType Directory -Force | Out-Null

# If external AMCacheParser exists in tools folder, run it
$amcacheParser = "C:\Temp\Scripts\tools\AMCacheParser.exe"
if (Test-Path $amcacheParser) {
    try {
        & $amcacheParser -f "C:\Windows\AppCompat\Programs\Amcache.hve" --csv $amacDir 2>$null
    } catch {}
}

# Shellbags export (if SBECmd or other tool provided)
$sbe = "C:\Temp\Scripts\tools\SBECmd.exe"
if (Test-Path $sbe) {
    try { & $sbe -d "$env:LocalAppData\Microsoft\Windows" --csv $dumpRoot } catch {}
}

# Basic registry-ish information export using PowerShell (fallback)
try {
    $recent = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
        ForEach-Object {
            [PSCustomObject]@{ Key = $_.PSChildName; DisplayName = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DisplayName }
        }
    $recent | Export-Csv -Path (Join-Path $amacDir "InstalledPrograms.csv") -NoTypeInformation -Encoding UTF8
} catch {}
