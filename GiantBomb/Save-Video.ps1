Set-StrictMode -Version Latest

function Save-Video {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [string]$Type,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [long]$ContentLength,

        [Parameter(Mandatory=$true)]
        [DateTime]$LastModified
    )

    $DestinationDirectory = "$BaseDestination$Type\"

    while (!(Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $DestinationDirectory | Out-Null
    }

    $Output = "$($DestinationDirectory)$(Remove-InvalidFileNameChars $Name).mp4"

    if (Test-Path -LiteralPath $Output) {
        if ((Get-Item -LiteralPath $Output).Length -eq $JeffErrorSize) {
            if ($ContentLength -eq $JeffErrorSize) {
                Write-Host "Not going to bother (re)downloading the Jeff Error video.`n" -ForegroundColor Magenta

                return $false
            } else {
                Write-Host "Already have a Jeff Error video with this name, but let's replace it!" -ForegroundColor Yellow
                Remove-Item -Path $Output -Verbose
            }
        } else {
            if ((Get-Item -LiteralPath $Output).Length -eq $ContentLength) {
                Write-Host "'$Output' has already been downloaded.`n" -ForegroundColor Green
                (Get-Item -LiteralPath "$Output").LastWriteTime = $LastModified
            } elseif ((Get-Item -LiteralPath $Output).Length -eq 0) {
                Write-Host "A dummy placeholder already exists for '$Output'.`n" -ForegroundColor Green
                (Get-Item -LiteralPath "$Output").LastWriteTime = $LastModified
            } elseif ($ContentLength -eq $JeffErrorSize) {
                Write-Host "We're hitting the API limit and getting the Jeff Error instead of an actual video.`n" -ForegroundColor Magenta
            } else {
                Write-Host "'$Output' already exists, but is not the correct size.`n" -ForegroundColor Red
            }

            return $false
        }
    } elseif ($ContentLength -eq $JeffErrorSize) {
        Write-Host "Nothing exists locally for this video, but we're hitting the Jeff Error, so let's not download.`n" -ForegroundColor Magenta

        return $false
    }

    Write-Host "[$(Get-Date -Format yyyyMMdd.HHmmss)] Downloading $Type > $Name..." -ForegroundColor Cyan

    $StartTime = Get-Date

    Start-BitsTransfer -Source $Url -Destination $Output
    Start-Sleep -Milliseconds 1000

    Write-Host "[$(Get-Date -Format yyyyMMdd.HHmmss)] Downloaded $Type > $Name in" `
        "$([Math]::Round((Get-Date).Subtract($StartTime).TotalSeconds, 3)) second(s) /" `
        "$([Math]::Round((Get-Date).Subtract($StartTime).TotalMinutes, 3)) minute(s) /" `
        "$([Math]::Round((Get-Date).Subtract($StartTime).TotalHours, 3)) hour(s).`n" -ForegroundColor Cyan

    (Get-Item -LiteralPath "$Output").LastWriteTime = $LastModified

    return $true
}
