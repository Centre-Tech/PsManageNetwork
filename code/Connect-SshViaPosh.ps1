<#
.SYNOPSIS
Connects to a remote endpoint via SSH using PowerShell.

.DESCRIPTION
The Connect-SshViaPosh function establishes an SSH session to a remote endpoint using PowerShell. It disconnects any existing SSH sessions and then attempts to connect to the specified endpoint using the provided credentials.

.PARAMETER endpointIp
The IP address or hostname of the remote endpoint.

.PARAMETER creds
The credentials to use for the SSH connection. If not provided, the function will prompt for credentials.

.EXAMPLE
Connect-SshViaPosh -endpointIp "192.168.1.100" -creds (Get-Credential)

This example connects to the remote endpoint with the IP address "192.168.1.100" using the specified credentials.

.NOTES
This function requires the SSH module to be installed. You can install it by running 'Install-Module -Name SSHUtils' in PowerShell.

#>
function Connect-SshViaPosh {
    param (
        [string]
        $endpointIp,
        [pscredential]
        $creds
    )
    if (!$creds) {
        $creds = Get-Credential -Message ('endpointIp={0}' -f $endpointIp)
    }
    try {
        # Disconnects all SshSessions then attempts to connect via Ssh
        Get-SSHSession | Remove-SSHSession | out-null; $sshSession = New-SSHSession -ComputerName $endpointIp -Credential $creds
        return $sshSession
    }
    catch {
        Write-Error -Message ("Unable to establish Ssh session to endpointIp={0} " -f $endpointIp)
        exit
    }
} # Posh-Ssh Wrapper - New-SshSession with minimal error handling