Function Get-CAIQBreakGlassAssessment {
    <#
        .SYNOPSIS
        This function tests if a user is excluded from a conditional access policy.

        .DESCRIPTION
        This function tests if a user is excluded from a conditional access policy.
    
        .PARAMETER UserId
        The User Id to test.

        .PARAMETER Select
        The properties to select from the policy object.

        .EXAMPLE
        Get-CAIQBreakGlassAssessment -UserId "user@domain.com"

        .INPUTS
        System.String[]

        .OUTPUTS
        System.Object


    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true)]
        [Alias("BG","BreakGlassAccount","Id","Upn")]
        [string[]]$Userid,
        [Parameter(Mandatory=$false)]
        [string[]]$Select = ("Id","DisplayName","Description","State")
    
    )
    Begin {
        #Setting the default parameter values
        $PSDefaultParameterValues["Add-Member:MemberType"] = "NoteProperty"
        $PSDefaultParameterValues["Add-Member:Force"] = $true

        #Creating a list to store the output
        $output_obj = [System.Collections.Generic.List[PSObject]]::new()

    } Process {
        #Getting the policies
        $policies = Get-CAIQConditionalAccessPolicy

        #Adding the break glass account and excluded from policy to the policy object
        $policies | Add-Member -Name "BreakGlassAccount" -Value ""
        $policies | Add-Member -Name "ExcludedFromPolicy" -Value $false

        Try {
            #Looping through each break glass account
            foreach ($id in $userid) {
                #Getting the user object for the break glass account
                $user = Get-CAIQUser -UserId $id

                #Getting the user's group memberships
                $member_of = Get-CAIQUserMemberOf -UserId $user.id -Recursive

                #Looping through each policy
                foreach ($policy in $policies) {
                    #Creating a new policy object  
                    $policy_obj = $policy | Select-Object ($select + @("BreakGlassAccount","ExcludedFromPolicy"))
                    $policy_obj.BreakGlassAccount = $user.userPrincipalName

                    #Getting the group and user exclusions for the conditional access policy
                    $excluded_groups = $policy.conditions.users.excludeGroups
                    $excluded_users = $policy.conditions.users.excludeUsers

                    # Test-CAIQConditionalAccessExclusion parameters
                    $test_ca_params = @{}
                    $test_ca_params["User"] = $user.id
                    $test_ca_params["UserMemberOf"] = $member_of.id
                    $test_ca_params["ExcludeGroups"] = $excluded_groups
                    $test_ca_params["ExcludeUsers"] = $excluded_users

                    #Testing if the user is excluded from the policy
                    $is_excluded = Test-CAIQConditionalAccessUsersExclusion @test_ca_params
                    
                    #Adding the policy object to the output list
                    $policy_obj.ExcludedFromPolicy = $is_excluded
                    $output_obj.Add($policy_obj)
                
                }
            }
        }
        Catch {
            Write-Error -Message $_ -ErrorAction Stop

        }
    } End {
        $output_obj

    }
}
