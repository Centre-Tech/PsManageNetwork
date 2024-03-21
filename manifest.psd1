$items = Get-ChildItem -Name "*.ps*1" -Path $PSScriptRoot
New-ModuleManifest -Path $PSScriptRoot\$items[0] -RootModule $PSScriptRoot\$items[1] -FunctionsToExport '*'