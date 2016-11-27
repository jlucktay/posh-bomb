Set-StrictMode -Version Latest

function Convert-GameUrlForApi {
    #input e.g.
    # "http://www.giantbomb.com/hitman/3030-45150/"
    #output e.g.
    # "http://www.giantbomb.com/api/game/3030-45150/"

    param(
        [Parameter(Mandatory=$true)]
        [String]$Url
    )

    if ($Url -match "\/3030\-[0-9]+\/$") {
        return "http://www.giantbomb.com/api/game$($Matches[0])"
    } else {
        return $null
    }
}
