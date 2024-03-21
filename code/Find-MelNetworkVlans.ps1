<#
.SYNOPSIS
    This function is used to find VLANs on a network device and compare them with a reference VLAN list.

.DESCRIPTION
    The Find-MelNetworkVlans function connects to a network device via SSH and retrieves the VLAN information. It then compares the retrieved VLANs with a reference VLAN list and returns the differences.

.PARAMETER ip
    Specifies the IP address of the network device. This parameter is mandatory.

.PARAMETER creds
    Specifies the credentials (PScredential) to use for the SSH connection. This parameter is mandatory.

.PARAMETER referenceVlanIds
    Specifies the reference VLAN ID list (int32) to compare with the retrieved VLANs. This parameter is optional and only used when comparing VLANs.

.PARAMETER csvPath
    Specifies the path to export the results as a CSV file. This parameter is optional and only used when comparing VLANs.

.EXAMPLE
    Find-MelNetworkVlans -ip "192.168.1.1" -creds $creds

    This example connects to the network device with the IP address "192.168.1.1" using the specified credentials and retrieves the VLAN information.

.EXAMPLE
    Find-MelNetworkVlans -ip "192.168.1.1" -creds $creds -referenceVlanIds 1, 2, 3 -csvPath "C:\VlanComparison.csv"

    This example connects to the network device with the IP address "192.168.1.1" using the specified credentials, retrieves the VLAN information, compares it with the reference VLAN IDs (1, 2, 3), and exports the results to a CSV file at the specified path.

#>
function Find-MelNetworkVlans {
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

    # Connect to the network device via SSH
    $sshSession = Connect-SshViaPosh -creds $creds -endpointIp $ip
    $sshStream = New-SSHShellStream -SSHSession $sshSession

    # Send commands to the network device
    New-SshStreamCommand -command "enable" -SSHStream $sshStream
    New-SshStreamCommand -command "terminal length 999" -SSHStream $sshStream
    New-SshStreamCommand -command 'show run' -SSHStream $sshStream

    # Read the SSH stream and extract VLAN information
    $sshReturn = (($sshStream.Read()) -split "`r`n")
    $results = @()
    ($sshReturn.where({ $_ -like "*vlan*" -and $_ -like '*name*' })).foreach({ $results += [int32]($_.split('name')[0]).split('vlan')[-1] })

    # Close the SSH session
    $sshSession | Remove-SSHSession | Out-Null

    if ($PSBoundParameters['referenceVlanIds']) {
        # Compare the retrieved VLANs with the reference VLAN IDs
        $compare = $(Compare-Object -ReferenceObject $referenceVlanIds -DifferenceObject $results)

        # Create a custom object to store the comparison results
        $results = $([PSCustomObject]@{
                VlanIdsToAdd     = ($compare.where({ $_.sideIndicator -eq '<=' })).InputObject
                VlanIdsToRemove  = ($compare.where({ $_.sideIndicator -eq '=>' })).InputObject
                VlanIds          = $results.Clone()
                vlanIdsReference = $referenceVlanIds
            })

        if ($PSBoundParameters['csvPath']) {
            # Export the results to a CSV file
            $results.VlanIds = $results.VlanIds -join ','
            $results.VlanIdsToRemove = $results.VlanIdsToRemove -join ','
            $results.VlanIdsToAdd = $results.VlanIdsToAdd -join ','
            $results.vlanIdsReference = $results.vlanIdsReference -join ','
    
            export-csv -InputObject $results -Path $csvPath
        }
    }

    # Return the results
    return $results
}
