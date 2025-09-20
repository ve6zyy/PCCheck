# modules\QuickMFT.ps1 - quick filename sweep via Get-ChildItem (fast fallback)
$dumpRoot = "C:\Temp\Dump"
$mftDir = Join-Path $dumpRoot "MFT"
New-Item -Path $mftDir -ItemType Directory -Force | Out-Null

# Quick file-name enumeration of typical cheat file names/dirs
$commonPaths = @(
    "$env:ProgramFiles\*",
    "$env:ProgramFiles(x86)\*",
    "$env:UserProfile\Downloads\*",
    "$env:UserProfile\Desktop\*",
    "$env:LocalAppData\Temp\*"
)
$keywords = @("aimbot","triggerbot","cheat","hack","trainer","usbdeview","ro9an","abby","hitbox","clumsy","astra","hydro","leet","skript")
$out = @()
foreach ($p in $commonPaths) {
    try {
        Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            foreach ($k in $keywords) {
                if ($_.Name -match [regex]::Escape($k)) { $out += $_.FullName }
            }
        }
    } catch {}
}
$out | Sort-Object -Unique | Out-File -FilePath (Join-Path $mftDir "QuickScan.txt") -Encoding UTF8
