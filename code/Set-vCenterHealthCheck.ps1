function Set-vCenterHealthCheck {
        <#
        .SYNOPSIS
                Enable / Disable vCenter HealthCheck settings
        
        .DESCRIPTION
                This cmdlet allows you to enable, or disable, the VLAN HealthCheck feature in vCenter for any or all your distributed switches.
                You can enter the VDSwitch by hand or send it over the pipeline.
        
        .PARAMETER vdSwitchName_str
                Name pattern of the VDSwitch for which to get VLAN info (accepts regex patterns)
                Recommend just using a single VDSwitch. It will accept multiple VDSwitches but the results will not be broken down for each VDSwitch
        .PARAMETER EnableDVS_Vlan_Mtu_Health
                Enables the VLAN/MTU property in VLAN HealthCheck
        .PARAMETER DisableDVS_Vlan_Mtu_Health
                Disables the VLAN/MTU property in VLAN HealthCheck
        .PARAMETER EnableDVS_Teaming_Health
                Enables the DVS Teaming property in VLAN HealthCheck
        .PARAMETER DisableDVS_Teaming_Health
                Disables the DVS Teaming property in VLAN HealthCheck
        .PARAMETER Interval
                By Default, the VLAN Healthcheck runs every 1 minute. 
                Use this parameter to change that default to something higher than 1 minute.
         .EXAMPLE
                Get-VDSwitch | Set-vCenterHealthCheck -DisableDVS_Vlan_Mtu_Health
                Disables the VLAN/MTU portion of the VLAN HealthCheck
        .EXAMPLE
                Get-VDSwitch | Set-vCenterHealthCheck -EnableDVS_Vlan_Mtu_Health
                Enables the VLAN/MTU portion of the VLAN HealthCheck
        .EXAMPLE
                Set-vCenterHealthCheck -vdSwitchName_str <VDS Name> -DisableDVS_Vlan_Mtu_Health
                Disables the VLAN/MTU portion of the VLAN HealthCheck for <VDS Name> only
        .EXAMPLE
                Set-vCenterHealthCheck -vdSwitchName_str <VDS Name> -EnableDVS_Vlan_Mtu_Health
                Enables the VLAN/MTU portion of the VLAN HealthCheck for <VDS Name> only
        .NOTES
                PowerCLI must be installed.
                Must be connected to a vCenter.
                The output currently is just the Task ID. Need to work on the output.
    #>
        [CmdletBinding()]
        param (
                [parameter(
                        Mandatory = $true,
                        ValueFromPipeline = $true,
                        HelpMessage = "'Ctrl + C' to cancel the cmdlet. Then use 'Get-VDSwitch' to see what is available to you. Recommend just using a single VDSwitch.")]
                [string[]]$vdSwitchName_str,
                [switch]$EnableDVS_Vlan_Mtu_Health,
                [switch]$DisableDVS_Vlan_Mtu_Health,
                [switch]$EnableDVS_Teaming_Health,
                [switch]$DisableDVS_Teaming_Health,
                [int]$interval
        )
    
        Begin {
                $hshGetViewNetworkParams = @{
                        viewtype = "DistributedVirtualSwitch"
                        Property = "Name"
                }
    
                $healthCheckConfig = New-Object VMware.Vim.DVSHealthCheckConfig[] (2)
    
                if ($EnableDVS_Vlan_Mtu_Health) {
                        $healthCheckConfig[0] = New-Object VMware.Vim.VMwareDVSVlanMtuHealthCheckConfig
                        $healthCheckConfig[0].Enable = $true
                        $healthCheckConfig[0].Interval = $interval
                }
    
                if ($DisableDVS_Vlan_Mtu_Health) {
                        $healthCheckConfig[0] = New-Object VMware.Vim.VMwareDVSVlanMtuHealthCheckConfig
                        $healthCheckConfig[0].Enable = $false
                        $healthCheckConfig[0].Interval = 0
                }
                if ($EnableDVS_Teaming_Health) {
                        $healthCheckConfig[1] = New-Object VMware.Vim.VMwareDVSTeamingHealthCheckConfig
                        $healthCheckConfig[1].Enable = $true
                        $healthCheckConfig[1].Interval = $interval
                }
    
                if ($DisableDVS_Teaming_Health) {
                        $healthCheckConfig[1] = New-Object VMware.Vim.VMwareDVSTeamingHealthCheckConfig
                        $healthCheckConfig[1].Enable = $false
                        $healthCheckConfig[1].Interval = 0
                }
        }
        Process {
                foreach ($vdSwitch in $vdSwitchName_str) {
                        $hshGetViewNetworkParams["Filter"] = @{"Name" = "$vdSwitch" }
                        $_this = get-view @hshGetViewNetworkParams
                        $_this.UpdateDVSHealthCheckConfig_Task($healthCheckConfig)
                }
        }
        End {}
    
}