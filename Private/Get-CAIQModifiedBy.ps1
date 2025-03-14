Function Get-CAIQModifiedBy([object]$InputObject) {
    <#
        .SYNOPSIS
        This is a helper function that gets the modified by for a policy from the Entra ID audit logs.

        .DESCRIPTION
        This is a helper function that gets the modified by for a policy from the Entra ID audit logs.

        .PARAMETER PolicyId
        The ID of the policy.

        .INPUTS
        System.Object

        .OUTPUTS
        System.String

    #>
    # If the policy was modified by an app, then set the modified by to the app service principal name
    if ($inputObject.initiatedBy.app.servicePrincipalName) {
        return $inputObject.initiatedBy.app.servicePrincipalName
        
    # If the policy was modified by a user, then set the modified by to the user principal name
    } ElseIf ($inputObject.initiatedBy.user.userPrincipalName) {
        return $inputObject.initiatedBy.user.userPrincipalName
    
    # If the policy was modified by a Microsoft-managed policy, then set the modified by to "Microsoft-generated policy"
    # This is a workaround to detect when a policy was generated by a Microsoft-managed policy
    } ElseIf ($inputObject.targetResource.displayName.StartsWith("Microsoft-managed:")) {
        return "Microsoft-managed"
    
    # If the policy was modified by an unknown entity, then set the modified by to "Unknown"
    } Else {
        return "Unknown"
    
    }
}
