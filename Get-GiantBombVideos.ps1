$ErrorActionPreference = "Stop"

$ApiKeyFile = "$PSScriptRoot\GiantBombApiKey.json"

if (Test-Path -LiteralPath $ApiKeyFile) {
    $ApiKey = (Get-Content -LiteralPath $ApiKeyFile | ConvertFrom-Json).apikey
} else {
    throw "The API key file was not found at '$ApiKeyFile'."
}

Import-Module BitsTransfer

$BaseDestination = "$($env:HOME)\Videos\Giant Bomb\"
$JeffErrorPath = "$($BaseDestination)Jeff Error.mp4"
$JeffErrorSize = (Get-Item -LiteralPath $JeffErrorPath).Length
[DateTime]$JeffErrorDateModified = (Get-Item -LiteralPath $JeffErrorPath).LastWriteTime

# Write-Host "JeffErrorDateModified: $("{0:s}" -f $JeffErrorDateModified)"

# Empty arrays to fill up later
$Videos = @()
$ConvertedVideos = @()
$DownloadQueue = @()

#------------------------------------------------------------------------------

. "$PSScriptRoot\GiantBomb\Confirm-DownloadChoice.ps1"
. "$PSScriptRoot\GiantBomb\Convert-GameUrlForApi.ps1"
. "$PSScriptRoot\GiantBomb\Convert-VideoUrlForApi.ps1"
. "$PSScriptRoot\GiantBomb\Get-DownloadQueue.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromCategory.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromFeed.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromGame.ps1"
. "$PSScriptRoot\GiantBomb\Remove-InvalidFileNameChars.ps1"
. "$PSScriptRoot\GiantBomb\Save-Video.ps1"
. "$PSScriptRoot\GiantBomb\Search-Api.ps1"

#------------------------------------------------------------------------------

$Videos += "http://www.giantbomb.com/videos/the-witcher-3-blood-and-vino/2300-11206/"
$Videos += "http://www.giantbomb.com/videos/quick-look-gears-of-war-4/2300-11632/"
# $Videos += "http://www.giantbomb.com/videos/quick-look-butcher/2300-11638/"
# $Videos += "http://www.giantbomb.com/videos/alexs-extra-life-drumstravaganza-part-01/2300-11690/"

# $Videos += Search-Api "Endurance Run Shenmue"
# $Videos += Search-Api "Gears of War 4"

$Videos += Get-VideosFromGame "http://www.giantbomb.com/mercenaries-playground-of-destruction/3030-7633/"
$Videos += Get-VideosFromGame "http://www.giantbomb.com/mercenaries-2-world-in-flames/3030-20697/"
$Videos += Get-VideosFromGame "http://www.giantbomb.com/mercs-inc/3030-29285/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/destiny/3030-36067/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/the-legend-of-zelda-breath-of-the-wild/3030-41355/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/the-witcher-3-wild-hunt/3030-41484/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/hitman/3030-45150/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/gears-of-war-4/3030-45269/"
$Videos += Get-VideosFromGame "http://www.giantbomb.com/mass-effect-andromeda/3030-46631/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/rise-of-the-tomb-raider/3030-46549/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/rock-band-4/3030-49077/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/titanfall-2/3030-49139/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/everspace/3030-52950/"
# $Videos += Get-VideosFromGame "http://www.giantbomb.com/watch-dogs-2/3030-54066/"

<# categories

Invoke-WebRequest -UseBasicParsing -Uri "http://www.giantbomb.com/api/video_categories/?api_key=$ApiKey&format=json" | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty results | Format-Table -Property id,name,deck

id name
-- ----
 2 Reviews
 3 Quick Looks
 4 TANG
 5 Endurance Run
 6 Events
 7 Trailers
 8 Features
10 Premium
11 Extra Life
12 Encyclopedia Bombastica
13 Unfinished
17 Metal Gear Scanlon
18 VinnyVania
19 Breaking Brad
20 Best of Giant Bomb
21 Game Tapes
22 Kerbal: Project B.E.A.S.T
23 Giant Bombcast
24 Blue Bombin'
#>

# $Videos += Get-VideosFromCategory 7
# $Videos += Get-VideosFromCategory 17
# $Videos += Get-VideosFromCategory 19
# $Videos += Get-VideosFromCategory 20
# $Videos += Get-VideosFromCategory 22

# $Videos += Get-VideosFromFeed "http://www.giantbomb.com/feeds/video/"

# $Videos
# $Videos | Format-Table | Write-Host
# $Videos | Sort-Object | Get-Unique | Format-Table | Write-Host

#------------------------------------------------------------------------------

if ($Videos.Length -eq 0) {
    Write-Host "There are zero videos queued for download. Bye!"
    exit 0
}

#------------------------------------------------------------------------------

foreach ($Video in ($Videos | Sort-Object | Get-Unique)) {
    $ConvertedVideos += Convert-VideoUrlForApi $Video
}

# Sort the videos by their unique IDs in the tail end of the URL
$ConvertedVideos = $ConvertedVideos | Sort-Object { [long]($_.Substring($_.IndexOf("-") + 1, $_.Substring($_.IndexOf("-") + 1).Length - 1)) }
$TotalSize = 0

# $ConvertedVideos | Format-Table | Write-Host

Write-Host "$($ConvertedVideos.Count) video(s) queued.`n"

$JeffErrorLimitHit = $false
$DownloadQueue += Get-DownloadQueue $ConvertedVideos ([ref]$JeffErrorLimitHit)
$DownloadsCompleted = 0

if ($DownloadQueue.Count -gt 0) {
    Write-Host "`nDownload queue:"

    $DownloadQueue.GetEnumerator() | ForEach-Object { Write-Host "`t$($_.type) > $($_.name) ($($_.url))" }

    Write-Host

    foreach ($Download in $DownloadQueue) {
        if ($JeffErrorLimitHit) {
            Write-Host "Jeff Error limit was hit; skipping download of '$($Download.type) > $($Download.name)'.`n" -ForegroundColor Yellow

            continue
        }

        if ([Uri]::IsWellFormedUriString($($Download.url), [UriKind]::Absolute)) {
            $GetVideoUrl = "$($Download.url)?api_key=$($ApiKey)"

            $HeadResponse = Invoke-WebRequest -Method Head -Uri $GetVideoUrl
            Start-Sleep -Milliseconds 1000

            [long]$VideoSize = $HeadResponse.Headers['Content-Length']
            [DateTime]$VideoLastModified = [DateTime]::Parse($HeadResponse.Headers['Last-Modified'])

            if ($VideoLastModified -eq $JeffErrorDateModified) {
                Write-Host "Jeff Error limit has been hit; skipping download of '$($Download.name)'.`n" -ForegroundColor Red
                $JeffErrorLimitHit = $true
            }

            if (!($JeffErrorLimitHit)) {
                Write-Host "$($Download.type) > $($Download.name)"
                Write-Host "`tLast-Modified:`t$("{0:s}" -f $VideoLastModified)"
                Write-Host ("`t{0:N0}`t{1}" -f $VideoSize, $Download.url)

                if ((Save-Video `
                    -Url $GetVideoUrl `
                    -VideoName $Download.name `
                    -VideoType $Download.type `
                    -ContentLength $VideoSize `
                    -VideoLastModified $VideoLastModified) -eq $true ) {
                        $TotalSize += $VideoSize
                        $DownloadsCompleted += 1
                    }
            }
        } else {
            Write-Host "The URI '$($Download.url)' for '$($Download.name)' is either not well-formed or not absolute. :(" -ForegroundColor Red
        }
    }

    Write-Host ("Total downloaded bytes: {0:N0}" -f $TotalSize)
}

# If zero downloads are completed from those looked up, exit with a non-zero code at the end
if ($DownloadsCompleted -eq 0) {
    Write-Host "Zero downloads from $($ConvertedVideos.Count) video(s) found.`n" -ForegroundColor Red
    exit $ConvertedVideos.Count
} else {
    Write-Host "Downloads completed: $($DownloadsCompleted)`n"
}
