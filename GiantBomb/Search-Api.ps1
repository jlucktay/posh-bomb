Set-StrictMode -Version Latest

function Search-Api {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query
    )

    $BaseSearchUrl = "http://www.giantbomb.com/api/search/?api_key=$ApiKey&format=json&query=""$([Uri]::EscapeDataString($Query.ToLower()))""&resources=video&field_list=site_detail_url"

    Write-Host "Searching for '$($Query.ToLower())'... " -NoNewline

    $Response = ((Invoke-WebRequest -Uri "$BaseSearchUrl&limit=1").Content | ConvertFrom-Json)
    Start-Sleep -Milliseconds 1000

    Write-Host "Found $($Response.number_of_total_results) raw result(s)... " -NoNewline

    $ResultCount = 0
    $ResultPage = 1
    $PageResults = @()

    while ($ResultCount -lt $($Response.number_of_total_results)) {
        Write-Host "." -NoNewline

        $PageResponse = ((Invoke-WebRequest -Uri "$BaseSearchUrl&page=$ResultPage").Content | ConvertFrom-Json)
        Start-Sleep -Milliseconds 1000

        $ResultCount += $PageResponse.number_of_page_results
        $ResultPage++
        $PageResults += $PageResponse.results
    }

    $Return = @()

    foreach ($Result in $PageResults) {
        $Match = $true

        foreach ($Token in $($Query.ToLower()) -split " ") {
            if (!($Result -imatch $Token)) { $Match = $false }
        }

        if ($Match) { $Return += $Result.site_detail_url }
    }

    $Return = $Return | Get-Unique

    Write-Host " Filtered to $(if ($Return) { $Return.Count } else { "0" }) matching unique result(s)."

    return $Return
}
