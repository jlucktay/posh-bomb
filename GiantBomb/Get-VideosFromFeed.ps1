Set-StrictMode -Version Latest

function Get-VideosFromFeed {
    param(
        [Parameter(Mandatory=$true)]
        [String]$VideoFeedUrl
    )

    Write-Host "Getting video feed '$($VideoFeedUrl)'..." -NoNewline

    $VideoFeedResponse = ([xml](Invoke-WebRequest -Uri "$($VideoFeedUrl)").Content).rss.channel.item
    Start-Sleep -Milliseconds 1000

    $Return = @()

    foreach ($VideoFeedItem in $VideoFeedResponse) {
        $Return += $VideoFeedItem.link
    }

    Write-Host " Got $($Return.Count) video(s) from feed $($VideoFeedUrl)."

    return $Return
}
