# modules\MFT.ps1
$dumpRoot = "C:\Temp\Dump"
$mftOutDir = Join-Path $dumpRoot "MFT"
New-Item -Path $mftOutDir -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path $mftOutDir "Raw") -ItemType Directory -Force | Out-Null

# If MFTECmd.exe is available in the same folder as scripts, use it
$mftePathCandidates = @(
    "C:\Temp\Scripts\tools\MFTECmd.exe",
    "C:\Temp\Scripts\MFTECmd.exe",
    "C:\tools\MFTECmd.exe"
)
$mfte = $mftePathCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($mfte) {
    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    foreach ($d in $drives) {
        try {
            & $mfte -f "${d}`$MFT" --fl --csv (Join-Path $mftOutDir "Raw") 2>$null
        } catch {}
    }
}

# Aggregate CSVs if present into single MFT.csv
$allCsvs = Get-ChildItem -Path (Join-Path $mftOutDir "Raw") -Filter *.csv -ErrorAction SilentlyContinue
if ($allCsvs) {
    $outFile = Join-Path $mftOutDir "MFT.csv"
    Remove-Item -Path $outFile -ErrorAction SilentlyContinue
    foreach ($c in $allCsvs) {
        try {
            Import-Csv $c.FullName -ErrorAction SilentlyContinue | Export-Csv -Path $outFile -NoTypeInformation -Append -Encoding UTF8
        } catch {}
    }
}
