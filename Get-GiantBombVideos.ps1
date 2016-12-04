param(
    [Parameter(HelpMessage="One or more video page URLs.")]
    [Alias("Url","Video","VideoUrl")]
    [ValidatePattern('^http:\/\/www.giantbomb.com\/videos\/[a-z0-9\-]+\/2300-[0-9]+\/$')]
    [ValidateScript({[Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute)})]
    [string[]]$VideoPageUrl,

    [Parameter(HelpMessage="Set this switch to add videos from the RSS feed.")]
    [Alias("AddFromFeed","Feed","VideoFeed")]
    [Switch]
    $AddVideosFromFeed,

    [Parameter(HelpMessage="One or more strings to search for.")]
    [Alias("SearchString")]
    [ValidatePattern('^[a-z0-9 ]+$')]
    [string[]]$Search,

    [Parameter(HelpMessage="One or more game page URLs.")]
    [Alias("Game","GameUrl")]
    [ValidatePattern('^http:\/\/www.giantbomb.com\/[a-z0-9\-]+\/3030-[0-9]+\/$')]
    [ValidateScript({[Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute)})]
    [string[]]$GamePageUrl,

    [Parameter(HelpMessage="One or more video category numbers.")]
    [Alias("Category")]
    [int[]]$VideoCategory,

    [Parameter(HelpMessage="Skip the confirmation prompts and don't download anything.")]
    [Switch]
    $SkipConfirm,

    [Parameter(HelpMessage="Stop running if/when we run into the Jeff Error.")]
    [Alias("Jeff","JeffError")]
    [Switch]
    $JeffErrorQuit
)

#------------------------------------------------------------------------------
# Set up some things like the secret API key, import some modules, initialise some variables

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

# Empty arrays to fill up later
$Videos = @()
$ConvertedVideos = @()
$DownloadQueue = @()

#------------------------------------------------------------------------------
# Import functions

. "$PSScriptRoot\GiantBomb\Confirm-DownloadChoice.ps1"
. "$PSScriptRoot\GiantBomb\Convert-UrlForApi.ps1"
. "$PSScriptRoot\GiantBomb\Get-DownloadQueue.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromCategory.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromFeed.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromGame.ps1"
. "$PSScriptRoot\GiantBomb\Remove-InvalidFileNameChars.ps1"
. "$PSScriptRoot\GiantBomb\Save-Video.ps1"
. "$PSScriptRoot\GiantBomb\Search-Api.ps1"

#------------------------------------------------------------------------------
# Parse in parameter inputs

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
# Bail out if nothing is queued up

if ($Videos.Length -eq 0) {
    Write-Host "There are zero videos queued for download. Bye!"
    exit 0
}

#------------------------------------------------------------------------------
# Set up a single queue in a known format

foreach ($Video in ($Videos | Sort-Object | Get-Unique)) {
    $ConvertedVideos += Convert-UrlForApi $Video
}

# Sort the videos by their unique IDs in the tail end of the URL
$ConvertedVideos = $ConvertedVideos | Sort-Object { [long]($_.Substring($_.IndexOf("-") + 1, $_.Substring($_.IndexOf("-") + 1).Length - 1)) }
$TotalSize = 0

Write-Host "$($ConvertedVideos.Count) video(s) queued.`n"

# Go through the queue and prompt for download confirmation
$JeffErrorLimitHit = $false
$DownloadQueue += Get-DownloadQueue $ConvertedVideos ([ref]$JeffErrorLimitHit)
$DownloadsCompleted = 0

if ($DownloadQueue.Count -gt 0) {
    Write-Host "`nDownload queue:"

    $DownloadQueue.GetEnumerator() | ForEach-Object { Write-Host "`t$($_.Type) > $($_.Name) ($($_.Url))" }

    Write-Host

    foreach ($Download in $DownloadQueue) {
        if ($JeffErrorLimitHit) {
            Write-Host "Jeff Error limit was hit; skipping download of '$($Download.Type) > $($Download.Name)'.`n" -ForegroundColor Yellow
            continue
        }

        if (!([Uri]::IsWellFormedUriString($($Download.Url), [UriKind]::Absolute))) {
            Write-Host "The URI '$($Download.Url)' for '$($Download.Name)' is either not well-formed or not absolute. :(" -ForegroundColor Red
            continue
        }

        $Download.Url += "?api_key=$($ApiKey)"

        $HeadResponse = Invoke-WebRequest -Method Head -Uri $Download.Url
        Start-Sleep -Milliseconds 1000

        [long]$VideoSize = $HeadResponse.Headers['Content-Length']
        [DateTime]$VideoLastModified = [DateTime]::Parse($HeadResponse.Headers['Last-Modified'])

        if ($VideoLastModified -eq $JeffErrorDateModified) {
            if ($JeffErrorQuit) {
                Write-Host "Jeff Error limit has been hit; quitting." -ForegroundColor Red
                exit 1
            }

            Write-Host "Jeff Error limit has been hit; skipping download of '$($Download.Type) > $($Download.Name)'.`n" -ForegroundColor Red
            $JeffErrorLimitHit = $true
            continue
        }

        Write-Host "$($Download.Type) > $($Download.Name)"
        Write-Host "`tLast-Modified:`t$("{0:s}" -f $VideoLastModified)"
        Write-Host ("`t{0:N0}`t{1}" -f $VideoSize, $Download.Url)

        $SaveVideoResult = Save-Video @Download -ContentLength $VideoSize -LastModified $VideoLastModified

        if ($SaveVideoResult -eq $true) {
            $TotalSize += $VideoSize
            $DownloadsCompleted += 1
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
