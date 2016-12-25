$ErrorActionPreference = "Stop"
# Set-StrictMode -Version Latest

function Foo {
    [CmdletBinding(SupportsShouldProcess=1)]
    param()

    Process {
        $PSBoundParameters
    }
}

Trace-Command -Name ParameterBinding -Expression {Foo -WhatIf:$xyzzy} -PSHost
