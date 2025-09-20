# modules\Packers.ps1 - basic signature / packer detection skeleton
$dumpRoot = "C:\Temp\Dump"
$packDir = Join-Path $dumpRoot "Packers"
New-Item -Path $packDir -ItemType Directory -Force | Out-Null

# scan common exe paths for suspicious file properties (simple heuristics)
$paths = @("$env:ProgramFiles\*","$env:ProgramFiles(x86)\*","$env:UserProfile\Downloads\*")
$results = @()
foreach ($p in $paths) {
    try {
        Get-ChildItem -Path $p -Recurse -Include *.exe -ErrorAction SilentlyContinue | ForEach-Object {
            $fi = $_
            $ver = $null
            try { $ver = (Get-ItemProperty -Path $fi.FullName -Name VersionInfo -ErrorAction SilentlyContinue).VersionInfo } catch {}
            $entropy = [Math]::Round((Get-FileHash -Algorithm SHA256 -Path $fi.FullName -ErrorAction SilentlyContinue).Hash.Length,2)
            $results += [PSCustomObject]@{
                File = $fi.FullName
                Length = $fi.Length
                Version = ($ver.FileVersion -as [string])
            }
        }
    } catch {}
}
$results | Export-Csv -Path (Join-Path $packDir "ExeSnapshot.csv") -NoTypeInformation -Encoding UTF8
