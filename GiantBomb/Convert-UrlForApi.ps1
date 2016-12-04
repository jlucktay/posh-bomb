$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Convert-UrlForApi {
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^http:\/\/www.giantbomb.com\/(videos\/)?[a-z0-9\-]+\/[0-9]+-')]
        [ValidateScript({[Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute)})]
        [String]$Url
    )

    if ($Url -match "\/3030\-[0-9]+\/$") {
        return "http://www.giantbomb.com/api/game$($Matches[0])"
    } elseif ($Url -match "\/2300\-[0-9]+\/$") {
        return "http://www.giantbomb.com/api/video$($Matches[0])"
    } else {
        return $null
    }
}
