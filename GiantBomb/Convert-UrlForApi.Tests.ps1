$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Convert-UrlForApi" {

    It "requires the URL parameter" -Skip {
        { Convert-UrlForApi -Confirm:$false } |
            Should Throw
    }

    It "requires a value for the URL parameter" {
        { Convert-UrlForApi -Url } |
            Should Throw
    }

    It "requires valid input for the URL parameter" {
        { Convert-UrlForApi -Url "" } |
            Should Throw
    }

    It "only accepts well-formed URLs" {
        { Convert-UrlForApi -Url "http/www.google" } |
            Should Throw
    }

    It "only accepts Giant Bomb URLs" {
        { Convert-UrlForApi -Url "http://www.google.com.au" } |
            Should Throw
    }

    It "returns null when appropriate" {
        Convert-UrlForApi -Url "http://www.giantbomb.com/hitman/3030-abc/" |
            Should Be $null
    }

    It "converts a game URL accurately" {
        Convert-UrlForApi -Url "http://www.giantbomb.com/hitman/3030-45150/" |
            Should BeExactly "http://www.giantbomb.com/api/game/3030-45150/"
    }

    It "converts a video URL accurately" {
        Convert-UrlForApi -Url "http://www.giantbomb.com/videos/quick-look-final-fantasy-xv/2300-11743/" |
            Should BeExactly "http://www.giantbomb.com/api/video/2300-11743/"
    }
}
