$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Convert-GameUrlForApi {
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^http:\/\/www.giantbomb.com\/[a-z0-9\-]+\/3030-[0-9]+\/$')]
        [ValidateScript({[Uri]::IsWellFormedUriString($($_), [UriKind]::Absolute)})]
        [String]$Url
    )

    Clear-Variable -Name Matches

    if ($Url -match "\/3030\-[0-9]+\/$") {
        return "http://www.giantbomb.com/api/game$($Matches[0])"
    }
}
