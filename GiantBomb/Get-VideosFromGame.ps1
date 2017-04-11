Set-StrictMode -Version Latest

function Get-VideosFromGame {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GameUrl
    )

    if ($GameUrl -notmatch '^https?:\/\/www\.giantbomb\.com\/([a-z0-9-]+)\/3030-([0-9]+)\/$') {
        return $false
    } <# else {
        Write-Host "Game ID # '$($Matches[2])' ('$($Matches[1])') found."
    } #>

    Write-Host "Getting videos from game '$($Matches[1])'..." -NoNewline

    $GameApiUrl = "$(Convert-UrlForApi $Matches[0])?api_key=$ApiKey&format=json&field_list=videos"

    $GameResponse = ((Invoke-WebRequest -Uri "$GameApiUrl").Content | ConvertFrom-Json)
    Start-Sleep -Milliseconds 1000

    $Return = @()

    foreach ($GameVideo in $GameResponse.results.videos) {
        $Return += $GameVideo.site_detail_url
    }

    Write-Host " Found $($Return.Count) video(s) for '$($Matches[1])'."

    return $Return
}
