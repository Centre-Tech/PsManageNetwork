<#
.SYNOPSIS
    Sends a command over an SSH stream.

.DESCRIPTION
    The New-SshStreamCommand function sends a command over an SSH stream.

.PARAMETER command
    The command to send over the SSH stream.

.PARAMETER sshStream
    The SSH stream to send the command over.

.EXAMPLE
    $sshStream = Get-SshStream
    New-SshStreamCommand -command "ls" -sshStream $sshStream

    This example sends the "ls" command over the SSH stream.

.NOTES
    Author: Your Name
    Date:   Current Date
#>
function New-SshStreamCommand {
    param (
        [string]
        $command,
        $sshStream
    )

    $sshStream.WriteLine(('{0}' -f $Command))
    start-sleep 6
}