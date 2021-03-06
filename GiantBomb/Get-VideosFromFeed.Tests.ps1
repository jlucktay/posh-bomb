$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Get-VideosFromFeed" {
    Context "Call IWR" {
        Mock Invoke-WebRequest {
            return New-Object -TypeName PSObject -Property @{
                Content = Get-Content -Path "$here\Get-VideosFromFeed.Tests.xml"
            }
        }

        It "Calls IWR and gets 3 items back" {
            $Result = Get-VideosFromFeed "http://www.giantbomb.com/feeds/video/"

            Assert-MockCalled Invoke-WebRequest -Exactly 1
            $Result.Count | Should Be 3
        }
    }
}
