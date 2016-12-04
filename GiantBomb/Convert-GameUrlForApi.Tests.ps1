$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Convert-GameUrlForApi" {
    It "requires the URL parameter" {
        { Convert-GameUrlForApi -Confirm:$false } |
            Should Throw
    }

    It "requires valid input for the URL parameter" {
        { Convert-GameUrlForApi -Url "" } |
            Should Throw
    }

    It "only accepts Giant Bomb game URLs" {
        { Convert-GameUrlForApi -Url "http://www.google.com.au" } |
            Should Throw
    }

    It "converts a game URL accurately" {
        Convert-GameUrlForApi -Url "http://www.giantbomb.com/hitman/3030-45150/" |
            Should Be "http://www.giantbomb.com/api/game/3030-45150/"
    }
}
