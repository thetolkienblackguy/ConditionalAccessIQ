Function Test-CAIQConditionalAccessUsersExclusion {
    <#
        .SYNOPSIS
        This function tests if a user is excluded from a conditional access policy.

        .DESCRIPTION
        This function tests if a user is excluded from a conditional access policy.

        .PARAMETER User
        The user object to test.

        .PARAMETER UserMemberOf
        The user's group memberships.

        .PARAMETER ExcludedGroups
        The groups that are excluded from the policy.

        .PARAMETER ExcludedUsers
        The users that are excluded from the policy.

        .EXAMPLE
        Test-CAIQConditionalAccessUsersExclusion -User $user -UserMemberOf $userMemberOf -ExcludeGroups $excludeGroups -ExcludeUsers $excludeUsers

        .INPUTS
        System.String[]

        .OUTPUTS
        System.Boolean
    
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$User,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$UserMemberOf,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$ExcludeGroups,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$ExcludeUsers
    
    )
    Begin {
        
    } Process {

        #Looping through each directory object
        Foreach ($directory_obj in @(@($user) + @($userMemberOf))) {
            #If the directory object is in any of the excluded groups or excluded users, then we return false
            If ($directory_obj -in @(@($excludeGroups) + @($excludeUsers))) {
                return $true

            }
        }
    } End {
        $false
    
    }
}