$dump = "C:\Temp\Dump\AMCache"; New-Item $dump -ItemType Directory -Force | Out-Null
$am = "C:\Temp\Scripts\tools\AmcacheParser.exe"
if (Test-Path $am) { & $am -f "C:\Windows\AppCompat\Programs\Amcache.hve" --csv $dump }
$sbe = "C:\Temp\Scripts\tools\SBECmd.exe"
if (Test-Path $sbe) { & $sbe -d "$env:LocalAppData\Microsoft\Windows" --csv $dump }
