
function Find-VmhostVlans {
    
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            HelpMessage = "VMhost name string")]
        [Alias("i")]
        [ValidateNotNullOrEmpty()]
        $vmhostName,

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

    #run health check
    $vmhostHealthCheck = (get-vmhost -state Connected, Maintenance -Name $vmhostName).foreach({ Get-VLANHealthCheck -vdSwitchName_str ($_ | Get-VdSwitch).Name -vmhostName_str $_.name })

    $results = ([PSCustomObject]@{

            healthCheck   = $vmhostHealthCheck
            unTrunkedVlan = @()
            trunkedVlan   = @()
            allVlan       = @()

        })

    # find unique untrunked vlans for all returned healthcheck objects
    ($vmhostHealthCheck.unTrunkedVlan.Split(',')).foreach({ $results.unTrunkedVlan += ([int32]$_) })
    $results.unTrunkedVlan = (($results.unTrunkedVlan | Select-Object -Unique) | Sort-Object)

    # find unique trunked vlans for all returned healthcheck objects
    ($vmhostHealthCheck.trunkedVlan.Split(',')).foreach({ $results.trunkedVlan += ([int32]$_) })
    $results.trunkedVlan = (($results.trunkedVlan | Select-Object -Unique) | Sort-Object)

    $results.allVlan = ($results.unTrunkedVlan + $results.trunkedVlan) | Select-Object -Unique

    if ($PSBoundParameters['ReferenceVlanIds']) {
        $compare = $(Compare-Object -ReferenceObject $referenceVlanIds -DifferenceObject $results.allVlan)
  
        $results = $([PSCustomObject]@{
                vlanIdsToAdd     = ($compare.where({ $_.sideIndicator -eq '<=' })).InputObject
                vlanIdsToRemove  = ($compare.where({ $_.sideIndicator -eq '=>' })).InputObject
                vlanIds          = $results.allVlan
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
