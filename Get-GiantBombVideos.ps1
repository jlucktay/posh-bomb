param(
    # URL(s) for video itself
    [Parameter(HelpMessage="One or more video page URLs.")]
    [Alias("Url","Video","VideoUrl")]
    [ValidatePattern('^http:\/\/www.giantbomb.com\/videos\/[a-z0-9\-]+\/2300-[0-9]+\/$')]
    [ValidateScript({[Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute)})]
    [string[]]$VideoPageUrl,

    # Add videos from the feed URL?
    [Parameter(HelpMessage="Set this switch to add videos from the RSS feed.")]
    [Alias("AddFromFeed","Feed","VideoFeed")]
    [Switch]
    $AddVideosFromFeed,

    # Search strings
    [Parameter(HelpMessage="One or more strings to search for.")]
    [Alias("SearchString")]
    [ValidatePattern('^[a-z0-9 ]+$')]
    [string[]]$Search,

    # URL(s) for game page
    [Parameter(HelpMessage="One or more game page URLs.")]
    [Alias("Game","GameUrl")]
    [ValidatePattern('^http:\/\/www.giantbomb.com\/[a-z0-9\-]+\/3030-[0-9]+\/$')]
    [ValidateScript({[Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute)})]
    [string[]]$GamePageUrl,

    # Category number(s)
    [Parameter(HelpMessage="One or more video category numbers.")]
    [Alias("Category")]
    [int[]]$VideoCategory,

    [Parameter(HelpMessage="Skip the confirmation prompts and don't download anything.")]
    [Switch]
    $SkipConfirm
)

#------------------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$ApiKeyFile = "$PSScriptRoot\GiantBombApiKey.json"

if (Test-Path -LiteralPath $ApiKeyFile) {
    $ApiKey = (Get-Content -LiteralPath $ApiKeyFile | ConvertFrom-Json).apikey
} else {
    throw "The API key file was not found at '$ApiKeyFile'."
}

Import-Module BitsTransfer

#------------------------------------------------------------------------------

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

foreach ($v in $VideoPageUrl) {
    $Videos += $v
}

if ($AddVideosFromFeed) {
    $Videos += Get-VideosFromFeed "http://www.giantbomb.com/feeds/video/"
}

foreach ($s in $Search) {
    $Videos += Search-Api $s
}

foreach ($g in $GamePageUrl) {
    $Videos += Get-VideosFromGame $g
}

foreach ($c in $VideoCategory) {
    $Videos += Get-VideosFromCategory $c
}

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
