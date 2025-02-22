Function Get-CAIQDeletedPolicies {
    <#
        .SYNOPSIS
        Helper function to identify possible deleted policies

        .DESCRIPTION
        Helper function to identify possible deleted policies

        .PARAMETER Path
        The path to the backup folder

        .PARAMETER Policies
        The policies to check for deletions

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [object[]]$Policies
    
    )

    # Get the backed up policies
    $backed_up_policies = (Get-ChildItem -Path "$($Path)\Policies" |Where-Object {
        $_.PSIsContainer -and ($_.Name -ne "Deleted")
    
    }).Name

    # Identify the deleted policies by comparing the backed up policies folder names which align with the object ID in the policy JSON
    $deleted_policies = $backed_up_policies | Where-Object {
        $_ -notin $policies.id
    
    }
    $deleted_policies
    
}

