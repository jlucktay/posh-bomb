$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Remove-InvalidFileNameChars" {
    It "requires a value for the Name parameter" {
        { Remove-InvalidFileNameChars -Name } |
            Should Throw
    }

    It "requires valid input for the Name parameter" {
        { Remove-InvalidFileNameChars -Name "" } |
            Should Throw
    }

    It "doesn't alter strings that are already technically valid" {
        Remove-InvalidFileNameChars -Name "!a£b`$c€d%e^" |
            Should Be "!a£b`$c€d%e^"
    }

    It "accurately modifies strings that are technically invalid" {
        Remove-InvalidFileNameChars -Name "\a/b:c*d?e`"f<g>h|" |
            Should Be "abcdefgh"
    }
}
