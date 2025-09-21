$dump = "C:\Temp\Dump\Packers"; New-Item $dump -ItemType Directory -Force | Out-Null
$paths = @("$env:ProgramFiles","$env:ProgramFiles(x86)","$env:UserProfile\Downloads")
Get-ChildItem -Path $paths -Recurse -Include *.exe -ErrorAction SilentlyContinue |
    Select-Object FullName,Length |
    Export-Csv (Join-Path $dump "ExeSnapshot.csv") -NoTypeInformation
