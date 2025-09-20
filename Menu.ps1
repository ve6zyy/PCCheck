# Menu.ps1
$ErrorActionPreference = "Stop"
$installRoot = "C:\Temp\Scripts"

function ShowMenu {
    Clear-Host
    Write-Host "PCCheck v2 - Menu`n"
    Write-Host " 1) Full Check"
    Write-Host " 2) Quick Check"
    Write-Host " 3) Process & Strings Check"
    Write-Host " 4) Advanced: Packers / Signatures"
    Write-Host " clean) Clean dump folder"
    Write-Host " 0) Exit"
    return Read-Host "Choose"
}

while ($true) {
    $choice = ShowMenu
    switch ($choice) {
        "1" {
            & (Join-Path $installRoot "PCCheck.ps1") -Mode Full
            Read-Host "Press Enter to return to menu"
        }
        "2" {
            & (Join-Path $installRoot "PCCheck.ps1") -Mode Quick
            Read-Host "Press Enter to return to menu"
        }
        "3" {
            & (Join-Path $installRoot "ProcDump.ps1")
            Read-Host "Press Enter to return to menu"
        }
        "4" {
            & (Join-Path $installRoot "Packers.ps1")
            Read-Host "Press Enter to return to menu"
        }
        "clean" {
            $dump = "C:\Temp\Dump"
            if (Test-Path $dump) {
                Remove-Item -Path (Join-Path $dump "*") -Recurse -Force -ErrorAction SilentlyContinue
                New-Item -Path $dump -ItemType Directory -Force | Out-Null
            }
            Write-Host "Dump cleaned."
            Start-Sleep -Seconds 1
        }
        "0" { break }
        default {
            Write-Host "Invalid choice"
            Start-Sleep -Seconds 1
        }
    }
}
