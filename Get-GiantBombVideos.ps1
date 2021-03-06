param(
    [Parameter(HelpMessage = "One or more video page URLs.")]
    [Alias("Url", "Video", "VideoUrl")]
    [ValidatePattern('^https?:\/\/www.giantbomb.com\/videos\/[a-z0-9\-]+\/2300-[0-9]+\/$')]
    [ValidateScript({ [Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute) })]
    [System.String[]] $VideoPageUrl,

    [Parameter(HelpMessage = "Specify this to add videos from the RSS feed.")]
    [Alias("AddFromFeed", "Feed", "VideoFeed")]
    [Switch] $AddVideosFromFeed,

    [Parameter(HelpMessage = "One or more strings to search for.")]
    [Alias("SearchString")]
    [ValidatePattern('^[a-z0-9 ]+$')]
    [System.String[]] $Search,

    [Parameter(HelpMessage = "One or more game page URLs.")]
    [Alias("Game", "GameUrl")]
    [ValidatePattern('^https?:\/\/www.giantbomb.com\/[a-z0-9\-]+\/3030-[0-9]+\/$')]
    [ValidateScript({ [Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute) })]
    [System.String[]] $GamePageUrl,

    [Parameter(HelpMessage = "One or more video category numbers.")]
    [Alias("Category")]
    [System.UInt64[]] $VideoCategory,

    [Parameter(HelpMessage = "One or more video show numbers.")]
    [Alias("Show")]
    [System.UInt64[]] $VideoShow,

    [Parameter(HelpMessage = "Get all of the videos. ALL OF THEM.")]
    [Alias("All", "Everything")]
    [Switch] $AllVideos,

    [Parameter(HelpMessage = "Skip ahead by this many videos when -AllVideos is true or searching with categories.")]
    [Alias("SkipToVideo")]
    [System.UInt64] $SkipIndex = 0,

    [Parameter(HelpMessage = "Skip the confirmation prompts and don't download anything.")]
    [Switch] $SkipConfirm,

    [Parameter(HelpMessage = "Quit immediately the first time we see the Jeff Error.")]
    [Switch] $JeffErrorQuit,

    [Parameter(HelpMessage = "Always say yes to the confirmation prompts and download everything.")]
    [Switch] $AlwaysConfirm
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Import-Module BitsTransfer

#------------------------------------------------------------------------------
# Set up some things like the secret API key, import some modules, initialise some variables

$ApiKeyFile = "$PSScriptRoot\GiantBombApiKey.json"

if (Test-Path -LiteralPath $ApiKeyFile) {
    $ApiKey = (Get-Content -LiteralPath $ApiKeyFile | ConvertFrom-Json).apikey
}
else {
    throw "The API key file was not found at '$ApiKeyFile'."
}

$BaseDestination = "$($env:HOME)\Videos\Giant Bomb\"
$JeffErrorPath = "$BaseDestination\Jeff Error.mp4"
$JeffErrorSize = (Get-Item -LiteralPath $JeffErrorPath).Length
[DateTime]$JeffErrorDateModified = (Get-Item -LiteralPath $JeffErrorPath).LastWriteTime
$VideoFileExtension = "mp4"

# Empty arrays to fill up later
$ConvertedVideos = @()
$DownloadQueue = @()
$SortedVideos = @()

#------------------------------------------------------------------------------
# Import functions

. "$PSScriptRoot\GiantBomb\Confirm-DownloadChoice.ps1"
. "$PSScriptRoot\GiantBomb\Convert-UrlForApi.ps1"
. "$PSScriptRoot\GiantBomb\Get-AllVideos.ps1"
. "$PSScriptRoot\GiantBomb\Get-DownloadQueue.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromCategory.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromFeed.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromGame.ps1"
. "$PSScriptRoot\GiantBomb\Get-VideosFromShow.ps1"
. "$PSScriptRoot\GiantBomb\Remove-InvalidFileNameChars.ps1"
. "$PSScriptRoot\GiantBomb\Save-Video.ps1"
. "$PSScriptRoot\GiantBomb\Search-Api.ps1"

#------------------------------------------------------------------------------
# Set up a single queue of API URLs to iterate through

$ConvertedList = New-Object System.Collections.Generic.List[System.String]

#------------------------------------------------------------------------------
# Parse in parameter inputs

if ($AllVideos) {
    foreach ($v in (Get-AllVideos -SkipIndex $SkipIndex)) {
        $ConvertedList.Add((Convert-UrlForApi $v))
    }
}

foreach ($v in $VideoPageUrl) {
    $ConvertedList.Add((Convert-UrlForApi $v))
}

if ($AddVideosFromFeed) {
    foreach ($v in (Get-VideosFromFeed "http://www.giantbomb.com/feeds/video/")) {
        $ConvertedList.Add((Convert-UrlForApi $v))
    }
}

foreach ($s in $Search) {
    foreach ($v in (Search-Api $s)) {
        $ConvertedList.Add((Convert-UrlForApi $v))
    }
}

foreach ($g in $GamePageUrl) {
    foreach ($v in (Get-VideosFromGame $g)) {
        $ConvertedList.Add((Convert-UrlForApi $v))
    }
}

foreach ($c in $VideoCategory) {
    foreach ($v in (Get-VideosFromCategory -VideoCategory $c -SkipIndex $SkipIndex)) {
        $ConvertedList.Add((Convert-UrlForApi $v))
    }
}

foreach ($s in $VideoShow) {
    foreach ($v in (Get-VideosFromShow -VideoShow $s -SkipIndex $SkipIndex)) {
        $ConvertedList.Add((Convert-UrlForApi $v))
    }
}

$ConvertedList.Sort()
$ConvertedVideos += $ConvertedList.ToArray() | Get-Unique

#------------------------------------------------------------------------------
# Bail out if nothing is queued up

if (($null -eq $ConvertedVideos) -or ($ConvertedVideos.Length -eq 0)) {
    Write-Host "There are zero videos queued for download. Bye!"
    exit 0
}

# Sort the videos by their unique IDs in the tail end of the URL
$SortedVideos += $ConvertedVideos | Sort-Object { [long]($_.Substring($_.IndexOf("-") + 1, $_.Substring($_.IndexOf("-") + 1).Length - 1)) }
$TotalSize = 0

Write-Host "$($SortedVideos.Count) video(s) queued.`n"

# Go through the queue and prompt for download confirmation
$JeffErrorLimitHit = $false
$DownloadQueue += Get-DownloadQueue $SortedVideos ([ref]$JeffErrorLimitHit)
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

        $Download.Url += "?api_key=$ApiKey"

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
        Write-Host ("`t{0:N0}`t{1}" -f $VideoSize, $($Download.Url).Replace("?api_key=$ApiKey", ""))

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
    Write-Host "Zero downloads from $($SortedVideos.Count) video(s) found.`n" -ForegroundColor Red
    exit $SortedVideos.Count
}
else {
    Write-Host "Downloads completed: $DownloadsCompleted`n"
}
