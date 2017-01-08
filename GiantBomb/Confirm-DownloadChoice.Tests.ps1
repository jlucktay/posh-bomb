$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Confirm-DownloadChoice" {
    It "requires the VideoName parameter" -Skip {
        Confirm-DownloadChoice -Confirm:$false |
            Should Throw
    }

    It "requires a value for the VideoName parameter" {
        { Confirm-DownloadChoice -VideoName } |
            Should Throw
    }

    It "returns false when SkipConfirm is set" {
        $SkipConfirm = $true
        Confirm-DownloadChoice -VideoName "random name" |
            Should Be $false
    }

    It "returns true when AlwaysConfirm is set" {
        $AlwaysConfirm = $true
        Confirm-DownloadChoice -VideoName "random name" |
            Should Be $true
    }
}
