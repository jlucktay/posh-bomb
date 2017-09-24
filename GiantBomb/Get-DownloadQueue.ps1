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
    $Counter = 1

    foreach ($Video in $ConvertedVideos) {
        $GetDetailsUrl = "$($Video)?api_key=$ApiKey&format=json&field_list=hd_url,name,video_type,publish_date,url"
        $Response = $null
        $FailCount = 0

        while ($Response -eq $null) {
            try {
                $RequestReturn = Invoke-WebRequest -Method Get -Uri $GetDetailsUrl -TimeoutSec 10
                $Response = $RequestReturn.Content | ConvertFrom-Json
            }
            catch {
                $FailCount++
                Write-Host -ForegroundColor Red -Object "Failed to get '$Video' $FailCount time(s), retrying in 5 seconds..."
                Start-Sleep -Seconds 4
            }
            finally {
                Start-Sleep -Seconds 1
            }
        }

        Write-Host "[$Counter/$($ConvertedVideos.Count)] " -NoNewline
        $Counter += 1

        if ($Response.error -ine "OK") {
            Write-Host "API response for '$Video' was not OK, skipping.`n" -ForegroundColor Red
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

        # Not every stream gets archived on the site
        if ($Response.url) {
            $CleanUrl = Remove-InvalidFileNameChars $Response.url
        } else {
            $CleanUrl = ".$VideoFileExtension"
        }

        $VideoPath = "$BaseDestination$CleanVideoType\$CleanName.$CleanUrl"

        if (Test-Path -LiteralPath $VideoPath) {
            if ((Get-Item -LiteralPath $VideoPath).Length -eq 0) {
                Write-Host "'$VideoPath' dummy file already exists, moving on!" -ForegroundColor DarkGreen
            } else {
                Write-Host "'$VideoPath' video file already exists, moving on!" -ForegroundColor Green
            }
        } else {
            if (Confirm-DownloadChoice "$(Remove-InvalidFileNameChars $Response.name)") {
                $DownloadQueue += @{
                    Url = "$($Response.hd_url)"
                    Type = "$($Response.video_type)"
                    Name = "$(Remove-InvalidFileNameChars $Response.name)"
                    File = "$($Response.url)"
                }
                Write-Host "Queued '$($Response.video_type) > $($Response.name)' for download!" -ForegroundColor Green
            } else {
                Write-Host "Creating a dummy placeholder for '$($Response.name)'..." -ForegroundColor Yellow
                New-Item -Path "$VideoPath" -ItemType File -Force | Out-Null
            }
        }

        if ($null -eq $Response.hd_url) {
            Write-Host "API response for '$Video' did not include a URL.`n" -ForegroundColor Red
            continue
        }

        if ($null -eq $Response.publish_date) {
            Write-Host "API response for '$Video' did not include a publish date.`n" -ForegroundColor Red
        } else {
            [DateTime]$VideoPublished = [DateTime]::Parse($Response.publish_date)

            if ((Test-Path -LiteralPath $VideoPath -PathType Leaf) `
            -and ((Get-Item -LiteralPath $VideoPath).Length -eq 0) `
            -and ( `
                ((Get-Item -LiteralPath $VideoPath).CreationTime -ne $VideoPublished) `
                -or ((Get-Item -LiteralPath $VideoPath).LastWriteTime -ne $VideoPublished) `
            )) {
                Write-Host "Setting timestamps on dummy file to publish date '$("{0:s}" -f $VideoPublished)'..." -ForegroundColor Cyan
                (Get-Item -LiteralPath "$VideoPath").CreationTime = $VideoPublished
                (Get-Item -LiteralPath "$VideoPath").LastWriteTime = $VideoPublished
            }
        }

        Write-Host
    }

    return $DownloadQueue
}
