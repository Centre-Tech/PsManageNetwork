<#
.SYNOPSIS
    Retrieves VLAN information from a Cisco network device.

.DESCRIPTION
    The Find-CiscoNetworkVlans function retrieves VLAN information from a Cisco network device using SSH. It connects to the device, runs the "show run" command to get the VLAN configuration, and returns the VLAN IDs. Optionally, it can also include the VLAN names, compare the VLAN IDs with a reference list, and export the results to a CSV file.

.PARAMETER ip
    Specifies the IP address of the Cisco network device.

.PARAMETER creds
    Specifies the credentials (username and password) to authenticate with the Cisco network device.

.PARAMETER vdc
    Specifies the virtual device context (VDC) to switch to before running the command. This parameter is optional.

.PARAMETER referenceVlanIds
    Specifies a reference list of VLAN IDs to compare with the retrieved VLAN IDs. This parameter is used in the "compare" parameter set and is optional.

.PARAMETER csvPath
    Specifies the path to export the results to a CSV file. This parameter is used in the "compare" parameter set and is optional.

.PARAMETER includeVlanName
    Indicates whether to include the VLAN names in the results. This parameter is used in the "include" parameter set and is optional.

.OUTPUTS
    If the "includeVlanName" parameter is specified, the function returns an array of VLAN IDs and their corresponding names.
    If the "referenceVlanIds" and "csvPath" parameters are specified, the function returns an object with the following properties:
        - VlanIdsToAdd: VLAN IDs that are in the reference list but not in the retrieved VLAN IDs.
        - VlanIdsToRemove: VLAN IDs that are in the retrieved VLAN IDs but not in the reference list.
        - VlanIds: Retrieved VLAN IDs.
        - vlanIdsReference: Reference VLAN IDs.
    If none of the above parameters are specified, the function returns an array of retrieved VLAN IDs.

.EXAMPLE
    PS C:\> Find-CiscoNetworkVlans -ip "192.168.1.1" -creds $creds

    Retrieves the VLAN IDs from the Cisco network device with the IP address "192.168.1.1" using the specified credentials.

.EXAMPLE
    PS C:\> Find-CiscoNetworkVlans -ip "192.168.1.1" -creds $creds -includeVlanName

    Retrieves the VLAN IDs and their corresponding names from the Cisco network device with the IP address "192.168.1.1" using the specified credentials.

.EXAMPLE
    PS C:\> Find-CiscoNetworkVlans -ip "192.168.1.1" -creds $creds -referenceVlanIds 10,20,30 -csvPath "C:\VlanComparison.csv"

    Retrieves the VLAN IDs from the Cisco network device with the IP address "192.168.1.1" using the specified credentials, compares them with the reference VLAN IDs (10, 20, 30), and exports the results to a CSV file at the specified path.

#>
function Find-CiscoNetworkVlans {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Default")]
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
            HelpMessage = "vdc.")]
        [Alias("v")]
        $vdc,

        [Parameter(Mandatory = $false,
            ParameterSetName = "compare",
            Position = 3,
            HelpMessage = "Reference vlan id list (int32).")]
        [Alias("r")]
        $referenceVlanIds,

        [Parameter(Mandatory = $false,
            ParameterSetName = "compare",
            Position = 4,
            HelpMessage = "Export to CSV")]
        [Alias("o")]
        $csvPath,

        [Parameter(Mandatory = $false,
            ParameterSetName = "include",
            Position = 5,
            HelpMessage = "include vlan Name")]
        [Alias("z")]
        $includeVlanName
    )

    $sshSession = Connect-SshViaPosh -creds $creds -endpointIp $ip
    $sshStream = New-SSHShellStream -SSHSession $sshSession
    

    if ($PSBoundParameters['vdc']) {
        New-SshStreamCommand -command ("switchto vdc {0}" -f $vdc) -SSHStream $sshStream
    }

    New-SshStreamCommand -command "terminal length 0" -SSHStream $sshStream
    New-SshStreamCommand -command 'show run' -SSHStream $sshStream

    $sshReturn = (($sshStream.Read()) -split "`r`n")
    $results = @()
    ($sshReturn.where({ $_ -like "vlan *" -and $_ -notlike "*,*" })).foreach({ $Results += [int32]($_.split('vlan '))[-1] })

    if ($PSBoundParameters['includeVlanName']) {
        $includeVlanName = @()

        foreach ($result in $results) {
            $sshSession = Connect-SshViaPosh -creds $creds -endpointIp $ip
            $showCommand = ("show vlan id {0} | grep act | cut -d ' ' -f 2-5" -f $result)
            $vlanName = $(((Invoke-SSHCommand -Command $showCommand -SSHSession $sshSession).output.trim()).split(' ')[0])
            $includeVlanName += $([PSCustomObject]@{
                    vlanId     = $result
                    vlanIdName = $vlanName
                })
        }
        $sshSession | Remove-SSHSession | Out-Null
        return $results, $includeVlanName
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

    $sshSession | Remove-SSHSession | Out-Null

    return $results
}
