<#
.SYNOPSIS
    Retrieves VLAN information from a Dell network device and compares it with a reference VLAN list.

.DESCRIPTION
    The Find-DellNetworkVlans function connects to a Dell network device using SSH and retrieves VLAN information using the 'show vlan brief' command.
    It then compares the retrieved VLANs with a reference VLAN list and returns the results.

.PARAMETER ip
    Specifies the IP address of the Dell network device. This parameter is mandatory.

.PARAMETER creds
    Specifies the credentials (PSCredential object) to use for authentication with the Dell network device. This parameter is mandatory.

.PARAMETER referenceVlanIds
    Specifies the reference VLAN IDs (int32) to compare with the retrieved VLANs. This parameter is optional and only used when the 'compare' parameter set is selected.

.PARAMETER csvPath
    Specifies the path to export the results as a CSV file. This parameter is optional and only used when the 'compare' parameter set is selected.

.EXAMPLE
    PS C:\> Find-DellNetworkVlans -ip "192.168.1.1" -creds $creds

    Retrieves VLAN information from the Dell network device with the IP address "192.168.1.1" using the specified credentials.

.EXAMPLE
    PS C:\> Find-DellNetworkVlans -ip "192.168.1.1" -creds $creds -referenceVlanIds 10,20,30 -csvPath "C:\VlanComparison.csv"

    Retrieves VLAN information from the Dell network device with the IP address "192.168.1.1" using the specified credentials.
    Compares the retrieved VLANs with the reference VLAN IDs (10, 20, 30) and exports the results to a CSV file at "C:\VlanComparison.csv".

#>
function Find-DellNetworkVlans {
    
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


    $sshSession = Connect-SshViaPosh -creds $creds -endpointIp $ip
    $sshStream = New-SSHShellStream -SSHSession $sshSession
    New-SshStreamCommand -command 'show vlan brief | no-more' -SSHStream $sshStream
    $sshReturn = (($sshStream.Read()) -split "`r`n")
    $outs = $sshReturn | Select-Object -Skip 4 | Select-Object -SkipLast 1

    $results = @()
    foreach ($line in $outs ) {
        $results += [int32]($line.Split('                                  ')[0])
    }

    $sshSession | Remove-SSHSession | Out-Null

    if ($PSBoundParameters['referenceVlanIds']) {
        $compare = $(Compare-Object -ReferenceObject $referenceVlanIds -DifferenceObject $results)

        $results = $([PSCustomObject]@{
                VlanIdsToAdd     = ($compare.where({ $_.sideIndicator -eq '<=' })).InputObject
                VlanIdsToRemove  = ($compare.where({ $_.sideIndicator -eq '=>' })).InputObject
                VlanIds          = $results.clone()
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
       
    
    return $results
    
}
