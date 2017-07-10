$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-AllVideos {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [long] $SkipIndex
    )

    Write-Host "Getting all videos$(if ($SkipIndex) { " (and skipping $SkipIndex)" })... " -NoNewline

    $BaseAllVideosUrl = "http://www.giantbomb.com/api/videos/?api_key=$ApiKey&format=json&field_list=site_detail_url&sort=id:asc"

    $InitialResponse = ((Invoke-WebRequest -Uri "$BaseAllVideosUrl&limit=1").Content | ConvertFrom-Json)
    Start-Sleep -Milliseconds 1000

    Write-Host "Found $($InitialResponse.number_of_total_results) result(s)... " -NoNewline

    $ResultCount = 0
    $ReturnList = New-Object System.Collections.Generic.List[System.String]

    while (($ResultCount + $SkipIndex) -lt $($InitialResponse.number_of_total_results)) {
        Write-Host "$($ResultCount + $SkipIndex) " -NoNewline

        $PageResponse = ((Invoke-WebRequest -Uri "$BaseAllVideosUrl&offset=$($ResultCount + $SkipIndex)").Content | ConvertFrom-Json)
        Start-Sleep -Milliseconds 1000

        $ResultCount += $PageResponse.number_of_page_results

        foreach ($v in $($PageResponse.results)) {
            $ReturnList.Add($v.site_detail_url)
        }
    }

    $Return = $ReturnList.ToArray()

    Write-Host "Found $ResultCount video(s)."

    return $Return
}
