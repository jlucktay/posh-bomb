function Convert-VideoUrlForApi {
    #input e.g.
    # "http://www.giantbomb.com/videos/jar-time-w-jeff-09122016/2300-11558/"
    #output e.g.
    # "http://www.giantbomb.com/api/video/2300-11558/"

    param(
        [Parameter(Mandatory=$true)]
        [String]$Url
    )

    if ($Url -match "\/2300\-[0-9]+\/$") {
        return "http://www.giantbomb.com/api/video$($Matches[0])"
    } else {
        return $null
    }
}
