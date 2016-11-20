function Get-VideosFromCategory {
    param(
        [Parameter(Mandatory=$true)]
        [int]$VideoCategory
    )

    Write-Host "Getting videos from category #$($VideoCategory)... " -NoNewline

    $BaseVideoCategoryUrl = "http://www.giantbomb.com/api/videos/?api_key=$($ApiKey)&format=json&sort=publish_date:asc&filter=video_type:$($VideoCategory)&field_list=site_detail_url,name"

    $CategoryResponse = ((Invoke-WebRequest -Uri "$($BaseVideoCategoryUrl)&limit=1").Content | ConvertFrom-Json)
    Start-Sleep -Milliseconds 1000

    Write-Host "Found $($CategoryResponse.number_of_total_results) result(s) in category #$($VideoCategory)... " -NoNewline

    $ResultCount = 0
    $ReturnList = New-Object System.Collections.Generic.List[System.String]

    while ($ResultCount -lt $($CategoryResponse.number_of_total_results)) {
        Write-Host "$ResultCount " -NoNewline

        $PageResponse = ((Invoke-WebRequest -Uri "$($BaseVideoCategoryUrl)&offset=$($ResultCount)").Content | ConvertFrom-Json)
        Start-Sleep -Milliseconds 1000

        $ResultCount += $PageResponse.number_of_page_results

        foreach ($CategoryVideo in $($PageResponse.results)) {
            $ReturnList.Add($CategoryVideo.site_detail_url)
        }
    }

    $Return = $ReturnList.ToArray()

    Write-Host "Found $ResultCount video(s) in category #$($VideoCategory)."

    return $Return
}
