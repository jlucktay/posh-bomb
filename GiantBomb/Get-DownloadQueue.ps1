$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. "$PSScriptRoot\Remove-InvalidFileNameChars.ps1"

function Get-DownloadQueue {
    param(
        [Parameter(Mandatory=$true)]
        $ConvertedVideos,

        [Parameter(Mandatory=$true)]
        [ref]$JeffErrorLimitHit
    )

    $DownloadQueue = @()

    # reading these globals:
    #   $ApiKey
    #   $BaseDestination
    #   $JeffErrorDateModified

    $Counter = 1

    foreach ($Video in $ConvertedVideos) {
        $GetDetailsUrl = "$($Video)?api_key=$ApiKey&format=json&field_list=hd_url,name,video_type"

        $Response = (Invoke-WebRequest -Method Get -Uri $GetDetailsUrl).Content | ConvertFrom-Json
        Start-Sleep -Milliseconds 1000

        Write-Host "[$Counter/$($ConvertedVideos.Count)] " -NoNewline
        $Counter += 1

        if ($Response.error -ine "OK") {
            Write-Host "API response for '$Video' was not OK, skipping." -ForegroundColor Red
            continue
        } else {
            $Response = $Response.results
        }

        if ($null -eq $Response.video_type) {
            $Response.video_type = "null"
        }

        Write-Host "$($Response.video_type) > $($Response.name)"

        $CleanVideoType = Remove-InvalidFileNameChars $Response.video_type
        $CleanName = Remove-InvalidFileNameChars $Response.name

        $VideoPath = "$BaseDestination$CleanVideoType\$CleanName.mp4"

        if (Test-Path -LiteralPath $VideoPath) {
            Write-Host "'$VideoPath' already exists, moving on!" -ForegroundColor DarkGreen
        } else {
            if (Confirm-DownloadChoice "$(Remove-InvalidFileNameChars $Response.name)") {
                $DownloadQueue += @{
                    Url = "$($Response.hd_url)"
                    Type = "$($Response.video_type)"
                    Name = "$(Remove-InvalidFileNameChars $Response.name)"
                }
                Write-Host "Queued '$($Response.video_type) > $($Response.name)' for download!" -ForegroundColor Green
            } else {
                Write-Host "Creating a dummy placeholder for '$($Response.name)'..." -ForegroundColor Yellow
                New-Item -Path "$VideoPath" -ItemType File -Force | Out-Null
            }
        }

        if (!($JeffErrorLimitHit.Value) `
        -and (Test-Path -LiteralPath $VideoPath -PathType Leaf) `
        -and ((Get-Item -LiteralPath $VideoPath).Length -eq 0) `
        -and (`
            ((Get-Item -LiteralPath $VideoPath).LastWriteTime -eq $JeffErrorDateModified) `
            -or (((Get-Item -LiteralPath $VideoPath).CreationTime) -eq (Get-Item -LiteralPath $VideoPath).LastWriteTime))
        ) {
            $HeadResponse = Invoke-WebRequest -Method Head -Uri "$($Response.hd_url)?api_key=$ApiKey"
            Start-Sleep -Milliseconds 1000

            [DateTime]$VideoLastModified = [DateTime]::Parse($HeadResponse.Headers['Last-Modified'])

            if ($VideoLastModified -ne $JeffErrorDateModified) {
                Write-Host "Fixing dummy timestamp to '$("{0:s}" -f $VideoLastModified)'..." -ForegroundColor Yellow
                (Get-Item -LiteralPath "$VideoPath").LastWriteTime = $VideoLastModified
            } else {
                if ($JeffErrorQuit) {
                    Write-Host "Jeff Error limit has been hit; quitting." -ForegroundColor Red
                    exit 1
                }

                Write-Host "Jeff Error limit has been hit." -ForegroundColor Red
                $JeffErrorLimitHit.Value = $true
            }
        } elseif ($JeffErrorLimitHit.Value `
        -and (Test-Path -LiteralPath $VideoPath -PathType Leaf) `
        -and ((Get-Item -LiteralPath $VideoPath).Length -eq 0) `
        -and ((Get-Item -LiteralPath $VideoPath).CreationTime -eq (Get-Item -LiteralPath $VideoPath).LastWriteTime)) {
            Write-Host "Jeff Error limit was hit; skipping timestamp fix for dummy of '$($Response.name)'." -ForegroundColor Yellow
        }

        Write-Host
    }

    return $DownloadQueue
}
