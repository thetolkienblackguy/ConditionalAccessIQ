Function Get-CAIQDirectoryObjectEndpoint($InputString) {
    <#
        .SYNOPSIS
        Helper function that returns the graphendpoint for the given input string.
    
        .DESCRIPTION
        Helper function that returns the graphendpoint for the given input string.
    
        .PARAMETER InputString
        The input string is the string that is used to determine the endpoint.

        .INPUTS
        System.String

        .OUTPUTS
        System.String
    
    
    #>
    # Switch statement to determine the Graph endpoint to use
    Switch -regex ($inputString) {
        'users|groups' {
            return "/directoryObjects"
        
        } 'applications' {
            return "/servicePrincipals"
          
        } 'roles' {
            return "/roleManagement/directory/roleDefinitions"
        
        } default {
            return $null
        
        }
    }
}