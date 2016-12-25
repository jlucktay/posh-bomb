$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Restart-InactiveComputer" {
   Mock Restart-Computer { "Restarting!" }

   Context "Computer should restart" {
      It "Restarts the computer if no users are logged on" {
         Mock Get-Process {}
         Restart-InactiveComputer | Out-Null
         Assert-MockCalled Restart-Computer -Exactly 1
      }
   }

   Context "Computer should not restart" {
      It "Does not restart the computer if a user is logged on" {
          Mock Get-Process { $true }
          Restart-InactiveComputer | Out-Null
          Assert-MockCalled Restart-Computer -Exactly 0
      }
   }
}
