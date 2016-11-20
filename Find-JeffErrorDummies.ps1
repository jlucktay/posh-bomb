# Finds dummy (zero size) files that still match the Jeff Error hence haven't been updated with their proper respective timestamps

$BaseDestination = "$($env:HOME)\Videos\Giant Bomb\"
$JeffErrorPath = "$($BaseDestination)Jeff Error.mp4"

Get-ChildItem -Recurse $BaseDestination `
| Where-Object { `
    !($_.PSIsContainer) `
    -and ((Get-Item -LiteralPath $_.FullName).Length -eq 0) `
    -and ( `
        ((Get-Item -LiteralPath $_.FullName).LastWriteTime -eq (Get-Item -LiteralPath $JeffErrorPath).LastWriteTime) `
        -or ((Get-Item -LiteralPath $_.FullName).CreationTime -eq (Get-Item -LiteralPath $_.FullName).LastWriteTime) `
    ) } `
| ForEach-Object { Write-Host $_.FullName }
