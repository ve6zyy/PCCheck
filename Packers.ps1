# Packers.ps1 - basic signature / packer detection skeleton (flat layout)
$dumpRoot = "C:\Temp\Dump"
$packDir = Join-Path $dumpRoot "Packers"
New-Item -Path $packDir -ItemType Directory -Force | Out-Null

# scan common exe paths for simple heuristics
$paths = @("$env:ProgramFiles\*","$env:ProgramFiles(x86)\*","$env:UserProfile\Downloads\*")
$results = @()
foreach ($p in $paths) {
    try {
        Get-ChildItem -Path $p -Recurse -Include *.exe -ErrorAction SilentlyContinue | ForEach-Object {
            $fi = $_
            $ver = $null
            try { $ver = (Get-ItemProperty -Path $fi.FullName -Name VersionInfo -ErrorAction SilentlyContinue).VersionInfo } catch {}
            $results += [PSCustomObject]@{
                File = $fi.FullName
                Length = $fi.Length
                Version = ($ver.FileVersion -as [string])
            }
        }
    } catch {}
}
$results | Export-Csv -Path (Join-Path $packDir "ExeSnapshot.csv") -NoTypeInformation -Encoding UTF8
