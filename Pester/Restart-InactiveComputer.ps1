function Restart-InactiveComputer {
    # [CmdletBinding(SupportsShouldProcess=$true)]
    # param()

    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Restart-Computer -Force
    }
}
