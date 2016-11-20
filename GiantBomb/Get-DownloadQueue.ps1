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
        $GetDetailsUrl = "$($Video)?api_key=$($ApiKey)&format=json&field_list=hd_url,name,video_type"
        # Write-Host "GetDetailsUrl: $GetDetailsUrl"

        $Response = ((Invoke-WebRequest -Method Get -Uri $GetDetailsUrl).Content | ConvertFrom-Json).results
        Start-Sleep -Milliseconds 1000

        Write-Host "[$($Counter)/$($ConvertedVideos.Count)] $($Response.video_type) > $($Response.name)"
        $Counter += 1

        $VideoPath = "$($BaseDestination)$(Remove-InvalidFileNameChars $Response.video_type)\$(Remove-InvalidFileNameChars $Response.name).mp4"

        if (Test-Path -LiteralPath $VideoPath) {
            Write-Host "'$($VideoPath)' already exists, moving on!" -ForegroundColor DarkGreen
        } else {
            if (Confirm-DownloadChoice "$(Remove-InvalidFileNameChars $Response.name)") {
                $DownloadQueue += @{
                    url = "$($Response.hd_url)";
                    name = "$(Remove-InvalidFileNameChars $Response.name)";
                    type = "$($Response.video_type)"
                }
                Write-Host "Queued '$($Response.video_type) > $($Response.name)' for download!" -ForegroundColor Green
            } else {
                Write-Host "Creating a dummy placeholder for '$($Response.name)'..." -ForegroundColor Yellow
                New-Item -Path "$($VideoPath)" -ItemType File -Force | Out-Null
            }
        }

        # Write-Host "JeffErrorLimitHit: $($JeffErrorLimitHit.Value)"
        # Write-Host "VideoPath: $VideoPath"
        # Write-Host "JeffErrorDateModified: $JeffErrorDateModified"
        # Write-Host "Test-Path: $(Test-Path -LiteralPath $VideoPath -PathType Leaf)"
        # Write-Host "Length: $((Get-Item -LiteralPath $VideoPath).Length)"
        # Write-Host "LastWriteTime: $((Get-Item -LiteralPath $VideoPath).LastWriteTime)"
        # Write-Host "CreationTime: $((Get-Item -LiteralPath $VideoPath).CreationTime)"

        if (!($JeffErrorLimitHit.Value) `
        -and (Test-Path -LiteralPath $VideoPath -PathType Leaf) `
        -and ((Get-Item -LiteralPath $VideoPath).Length -eq 0) `
        -and (`
            ((Get-Item -LiteralPath $VideoPath).LastWriteTime -eq $JeffErrorDateModified) `
            -or (((Get-Item -LiteralPath $VideoPath).CreationTime) -eq (Get-Item -LiteralPath $VideoPath).LastWriteTime))
        ) {
            $HeadResponse = Invoke-WebRequest -Method Head -Uri "$($Response.hd_url)?api_key=$($ApiKey)"
            Start-Sleep -Milliseconds 1000

            [DateTime]$VideoLastModified = [DateTime]::Parse($HeadResponse.Headers['Last-Modified'])

            if ($VideoLastModified -ne $JeffErrorDateModified) {
                Write-Host "Fixing dummy timestamp to '$("{0:s}" -f $VideoLastModified)'..." -ForegroundColor Yellow
                (Get-Item -LiteralPath "$($VideoPath)").LastWriteTime = $VideoLastModified
            } else {
                Write-Host "Jeff Error limit has been hit." -ForegroundColor Red
                $JeffErrorLimitHit.Value = $true
            }
        } elseif ($JeffErrorLimitHit.Value `
        -and (Test-Path -LiteralPath $VideoPath -PathType Leaf) `
        -and ((Get-Item -LiteralPath $VideoPath).CreationTime -eq (Get-Item -LiteralPath $VideoPath).LastWriteTime)) {
            Write-Host "Jeff Error limit was hit; skipping timestamp fix for dummy of '$($Response.name)'." -ForegroundColor Red
        }

        Write-Host
    }

    return $DownloadQueue
}
