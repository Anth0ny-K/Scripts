# GARCheck identifies GenericAllRights and converts the SIDs for easy review, it requires PowerView.ps1 to be imported prior to use.
# Default usage identifies GenericAllRights for the user executing the script, use -Identity for other users and objects or -h for help.
# Check if the user specified parameters
$IdentityName = $null
$ShowHelp = $false

# Parse the arguments manually
$args | ForEach-Object {
    if ($_ -eq "-h") {
        $ShowHelp = $true
    } elseif ($_ -like "-IdentityName*") {
        $IdentityName = ($_ -replace "-IdentityName=", "")
    }
}

# Define function to resolve a username or group name to its SID
function Get-SidFromName {
    param (
        [string]$Name
    )
    try {
        $sid = (New-Object System.Security.Principal.NTAccount($Name)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        return $sid
    } catch {
        Write-Error "Could not resolve the SID for $Name. Ensure the name is correct."
        return $null
    }
}

# Define script usage function
function Show-Usage {
    Write-Host "Usage: .\GenericAllRights.ps1 [-IdentityName=<UsernameOrGroup>] [-h]" -ForegroundColor Yellow
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -IdentityName=<UsernameOrGroup>  Specify the username or group to check for GenericAll rights. Default is the current user."
    Write-Host "  -h                               Show this help message."
}

# Show usage if -h is provided
if ($ShowHelp) {
    Show-Usage
    return
}

# Resolve the SID
if ($IdentityName -eq $null) {
    # Default to the current user if no name is provided
    $targetSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
} else {
    $targetSid = Get-SidFromName -Name $IdentityName
    if ($targetSid -eq $null) {
        return  # Exit if SID resolution fails
    }
}

# Enumerate ACLs and filter for GenericAll rights for the specified or current user
Get-DomainObjectAcl | Where-Object { 
    $_.ActiveDirectoryRights -eq "GenericAll" -and $_.SecurityIdentifier -eq $targetSid
} | ForEach-Object {
    [PSCustomObject]@{
        ObjectDN              = $_.ObjectDN
        ActiveDirectoryRights = $_.ActiveDirectoryRights
        ObjectSID             = $_.ObjectSID
        ObjectName            = Convert-SidToName $_.ObjectSID
        Identity              = (New-Object System.Security.Principal.SecurityIdentifier($_.SecurityIdentifier)).Translate([System.Security.Principal.NTAccount]).Value
    }
}
