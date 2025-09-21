$dump = "C:\Temp\Dump\MFT"; New-Item $dump -ItemType Directory -Force | Out-Null
$tool = "C:\Temp\Scripts\tools\MFTECmd.exe"
if (Test-Path $tool) {
    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -Expand Root
    foreach ($d in $drives) { & $tool -f "${d}`$MFT" --csv $dump --fl -q }
}
