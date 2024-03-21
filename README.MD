## Functionality

The `PsManageNetwork.psm1` module performs the following operations:

1. Tries to import the `Posh-SSH` and `VMware.PowerCLI` modules. If these modules are not installed, it installs them using the `Install-Module` cmdlet.
2. Imports all PowerShell scripts (with the `.ps1` extension) in the current directory and executes them using the dot sourcing operator (`.`). This allows the functions defined in those scripts to be used within the module.
3. Exports all the functions as module members using the `Export-ModuleMember` cmdlet. This makes the functions accessible to other scripts or modules that import this module.

## Usage

To use the `PsManageNetwork.psm1` module, you would typically import the module into your PowerShell session, and then call the functions defined in the imported scripts. For example:

```powershell
Import-Module .\PsManageNetwork.psm1
Get-Command -Module PsManageNetwork
```

## Requirements

This module requires PowerShell and the `Posh-SSH` and `VMware.PowerCLI` modules. If these modules are not installed, the module will attempt to install them.

## Contributing

Contributions to this module are welcome. Please ensure that any changes maintain the existing functionality of the module.

## License

This module is licensed under the terms of the license provided by the repository containing the module.