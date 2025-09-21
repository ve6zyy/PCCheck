$dump = "C:\Temp\Dump\MFT"; New-Item $dump -ItemType Directory -Force | Out-Null
$keywords = @("aimbot","cheat","hack","trainer")
$paths = @("$env:ProgramFiles","$env:ProgramFiles(x86)","$env:UserProfile\Downloads","$env:UserProfile\Desktop")
$hits = foreach ($p in $paths) { Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Where-Object { $keywords | ForEach-Object { $_ -and ($_.Name -match $_) } } }
$hits | Select-Object FullName | Out-File (Join-Path $dump "QuickScan.txt")
