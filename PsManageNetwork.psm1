<#
.SYNOPSIS
    This script imports all PowerShell scripts in the current directory and exports the functions defined in those scripts as module members.

.DESCRIPTION
    This script is designed to be used as a module. It imports all PowerShell scripts (with the extension .ps1) in the current directory and executes them using the dot sourcing operator (.). This allows the functions defined in those scripts to be used within the module.

    After importing the scripts, the script exports all the functions as module members using the Export-ModuleMember cmdlet. This makes the functions accessible to other scripts or modules that import this module.

.PARAMETER None
    This script does not accept any parameters.

.EXAMPLE
    Import-Module -Name module.psm1
    Get-MyFunction

    This example demonstrates how to import the module and use one of the functions defined in the imported scripts.

.NOTES
    - This script assumes that all the PowerShell scripts (.ps1) in the current directory are meant to be imported and their functions exported as module members.
    - If you want to exclude certain scripts or modify the behavior, you can modify the script accordingly.
#>

try {
    Import-module -Name Posh-SSH
    Import-module -Name VMware.PowerCLI
}
catch {
    Install-Module -Name Posh-SSH -Force
    Install-module -Name VMware.PowerCLI -Force
}

Get-ChildItem -Path $((Get-ChildItem -Directory).FullName) -File "*.ps1" | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function (Get-ChildItem -Path $((Get-ChildItem -Directory).FullName) -File "*.ps1").BaseName