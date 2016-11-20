function Confirm-DownloadChoice {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoName
    )

    $Message = "Confirm: do you really want to download '$($VideoName)'?"

    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "Definitely download this video."

    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "Let's not bother with this one."

    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
    $Result = $Host.UI.PromptForChoice("", $Message, $Options, 1)

    switch ($Result) {
        0 { return $true }
        1 { return $false }
    }
}
