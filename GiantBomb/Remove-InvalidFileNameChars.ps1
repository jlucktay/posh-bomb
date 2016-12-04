$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Remove-InvalidFileNameChars {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    $InvalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $Regex = "[{0}]" -f [RegEx]::Escape($InvalidChars)

    return ($Name -replace $Regex)
}
