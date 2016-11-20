function Remove-InvalidFileNameChars {
    param(
        [Parameter(Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [String]$Name
    )

    $InvalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $Regex = "[{0}]" -f [RegEx]::Escape($InvalidChars)

    return ($Name -replace $Regex)
}
