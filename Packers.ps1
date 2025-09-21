# Packers.ps1 - simple exe snapshot and heuristics
$dumpRoot = "C:\Temp\Dump"
$outDir = Join-Path $dumpRoot "Packers"
New-Item -Path $outDir -ItemType Directory -Force | Out-Null

$paths = @("$env:ProgramFiles","$env:ProgramFiles(x86)","$env:UserProfile\Downloads")
$results = @()
foreach ($p in $paths) {
    try {
        Get-ChildItem -Path $p -Recurse -Include *.exe -ErrorAction SilentlyContinue | ForEach-Object {
            $fi = $_
            $ver = $null
            try { $ver = (Get-ItemProperty -Path $fi.FullName -Name VersionInfo -ErrorAction SilentlyContinue).VersionInfo } catch {}
            $results += [PSCustomObject]@{ File=$fi.FullName; Length=$fi.Length; Version=($ver.FileVersion -as [string]) }
        }
    } catch {}
}
$results | Export-Csv -Path (Join-Path $outDir "ExeSnapshot.csv") -NoTypeInformation -Encoding UTF8
