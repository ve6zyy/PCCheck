# MFT.ps1 - run MFTECmd if present, else quick fallback
$dumpRoot = "C:\Temp\Dump"
$outDir = Join-Path $dumpRoot "MFT"
New-Item -Path $outDir -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $outDir "Raw") -ItemType Directory -Force | Out-Null

$tools = "C:\Temp\Scripts\tools"
$mfte = Get-ChildItem -Path $tools -Filter "MFTECmd.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($mfte) {
    Write-Host "MFTECmd found at $($mfte.FullName) - parsing MFT..."
    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    foreach ($d in $drives) {
        try {
            & $mfte.FullName -f "${d}`$MFT" --csv (Join-Path $outDir "Raw") --fl -q 2>$null
        } catch { Write-Warning "MFTECmd failed for $d: $_" }
    }
} else {
    Write-Warning "MFTECmd not found. Performing quick filename scan fallback."
    # fallback: simple file enumeration (fast)
    $keywords = @("aimbot","triggerbot","cheat","hack","trainer","usbdeview","ro9an","abby","hitbox","clumsy","astra","hydro","leet","skript")
    $paths = @("$env:ProgramFiles","$env:ProgramFiles(x86)","$env:UserProfile\Downloads","$env:UserProfile\Desktop")
    $out = @()
    foreach ($p in $paths) {
        try { Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | ForEach-Object { foreach ($k in $keywords) { if ($_.Name -match [regex]::Escape($k)) { $out += $_.FullName } } } } catch {}
    }
    $out | Sort-Object -Unique | Out-File -FilePath (Join-Path $outDir "QuickScan.txt") -Encoding UTF8
}

# Merge any CSVs to MFT.csv
$csvs = Get-ChildItem -Path (Join-Path $outDir "Raw") -Filter *.csv -ErrorAction SilentlyContinue
if ($csvs) {
    $outFile = Join-Path $outDir "MFT.csv"
    Remove-Item -Path $outFile -ErrorAction SilentlyContinue
    foreach ($c in $csvs) {
        try { Import-Csv $c.FullName | Export-Csv -Path $outFile -NoTypeInformation -Append -Encoding UTF8 } catch {}
    }
}
