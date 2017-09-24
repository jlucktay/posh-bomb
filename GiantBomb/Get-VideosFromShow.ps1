$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-VideosFromShow {
    param(
        [Parameter(Mandatory = $true)]
        [long] $VideoShow,

        [Parameter(Mandatory = $true)]
        [long] $SkipIndex
    )

    Write-Host "Getting videos from show #$VideoShow$(if ($SkipIndex) { " (and skipping $SkipIndex)" })... " -NoNewline

    $BaseVideoShowUrl = "http://www.giantbomb.com/api/videos/?api_key=$ApiKey&format=json&sort=publish_date:asc&filter=video_show:$VideoShow&field_list=site_detail_url,name"

    $ShowResponse = ((Invoke-WebRequest -Uri "$BaseVideoShowUrl&limit=1").Content | ConvertFrom-Json)
    Start-Sleep -Milliseconds 1000

    Write-Host "Found $($ShowResponse.number_of_total_results) result(s) in show #$VideoShow... " -NoNewline

    $ResultCount = 0
    $ReturnList = New-Object System.Collections.Generic.List[System.String]

    while (($ResultCount + $SkipIndex) -lt $($ShowResponse.number_of_total_results)) {
        Write-Host "$($ResultCount + $SkipIndex) " -NoNewline

        $PageResponse = ((Invoke-WebRequest -Uri "$BaseVideoShowUrl&offset=$($ResultCount + $SkipIndex)").Content | ConvertFrom-Json)
        Start-Sleep -Milliseconds 1000

        $ResultCount += $PageResponse.number_of_page_results

        foreach ($ShowVideo in $($PageResponse.results)) {
            $ReturnList.Add($ShowVideo.site_detail_url)
        }
    }

    $Return = $ReturnList.ToArray()

    Write-Host "Found $ResultCount video(s) in show #$VideoShow."

    return $Return
}
