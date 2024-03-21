<#
.SYNOPSIS
    Retrieves VLAN information from an HPE network device and compares it with a reference VLAN list.

.DESCRIPTION
    The Find-HpeNetworkVlans function retrieves VLAN information from an HPE network device using the HPE OneView module. 
    It can also compare the retrieved VLANs with a reference VLAN list and export the results to a CSV file.

.PARAMETER ip
    Specifies the IP address of the HPE network device.

.PARAMETER creds
    Specifies the credentials to authenticate with the HPE network device.

.PARAMETER referenceVlanIds
    Specifies a list of reference VLAN IDs (int32) to compare with the retrieved VLANs. This parameter is optional.

.PARAMETER csvPath
    Specifies the path to export the results to a CSV file. This parameter is optional.

.EXAMPLE
    Find-HpeNetworkVlans -ip "192.168.1.1" -creds $creds -referenceVlanIds 10,20,30 -csvPath "C:\VlanResults.csv"
    Retrieves VLAN information from the HPE network device with the IP address "192.168.1.1", compares it with the reference VLAN IDs 10, 20, and 30, and exports the results to "C:\VlanResults.csv".

#>

function Find-HpeNetworkVlans {
    
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = "Device IP.")]
        [Alias("i")]
        [ValidateNotNullOrEmpty()]
        $ip,

        [Parameter(Mandatory = $true,
            Position = 1,
            HelpMessage = "PScredential.")]
        [Alias("c")]
        [ValidateNotNullOrEmpty()]
        [pscredential]$creds,

        [Parameter(Mandatory = $false,
            Position = 2,
            ParameterSetName = "compare",
            HelpMessage = "Reference vlan id list (int32).")]
        [Alias("r")]
        $referenceVlanIds,

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = "compare",
            HelpMessage = "Export to CSV")]
        [Alias("o")]
        $csvPath
    )

    [HPEOneView.PKI.SslValidation]::IgnoreCertErrors = $true
    $ApplianceConnection = Connect-OVMgmt -Hostname $ip -Credential $Credential

    $outs = Get-OVNetwork


    $results = @()
    foreach ($line in ($outs.where({ $_.type -like "ethernet*" }).vlanid) ) {
        $results += ([int32]$line)
    }


    if ($PSBoundParameters['referenceVlanIds']) {
        $compare = $(Compare-Object -ReferenceObject $referenceVlanIds -DifferenceObject $results)

        $results = $([PSCustomObject]@{
                VlanIdsToAdd     = ($compare.where({ $_.sideIndicator -eq '<=' })).InputObject
                VlanIdsToRemove  = ($compare.where({ $_.sideIndicator -eq '=>' })).InputObject
                VlanIds          = $results.Clone()
                vlanIdsReference = $referenceVlanIds
            })

        if ($PSBoundParameters['csvPath']) {

            $results.VlanIds = $results.VlanIds -join ','
            $results.VlanIdsToRemove = $results.VlanIdsToRemove -join ','
            $results.VlanIdsToAdd = $results.VlanIdsToAdd -join ','
            $results.vlanIdsReference = $results.vlanIdsReference -join ','
    
            export-csv -InputObject $results -Path $csvPath
    
        }
    }
       
    $ApplianceConnection | Disconnect-OVMgmt
    
    return $results
    
}
