# Finds dummy (zero size) files with timestamps that match the Jeff Error, hence haven't been updated with their own correct timestamp

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$BaseDestination = "$($env:HOME)\Videos\Giant Bomb\"
$JeffErrorPath = "$BaseDestination\Jeff Error.mp4"

$Dummies = Get-ChildItem -Recurse $BaseDestination |
    Where-Object { `
        !($_.PSIsContainer) `
        -and ((Get-Item -LiteralPath $_.FullName).Length -eq 0) `
        -and ((Get-Item -LiteralPath $_.FullName).LastWriteTimeUtc -eq (Get-Item -LiteralPath $JeffErrorPath).LastWriteTimeUtc) `
    }

$Dummies | ForEach-Object { Write-Host $_.FullName }
Write-Host "# of dummies: $($Dummies | Measure-Object | Select-Object -ExpandProperty Count)"
