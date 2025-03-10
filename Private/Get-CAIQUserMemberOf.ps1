Function Get-CAIQUserMemberOf {
    <#
        .DESCRIPTION
        This function retrieves user's group memberships from the Microsoft Graph API.

        .SYNOPSIS
        This function retrieves user's group memberships from the Microsoft Graph API.

        .PARAMETER UserId
        The user ID of the user whose group memberships are to be retrieved.

        .PARAMETER Select
        The properties to be selected for the user information. The default properties are DisplayName, Id, Mail, and UserPrincipalName.

        .PARAMETER Recursive
        Retrieve the user's group memberships recursively.

        .PARAMETER Expand
        The properties to be expanded for the user information. 

        .PARAMETER All
        Retrieve all users.

        .EXAMPLE
        Get-CAIQUserMemberOf -UserId "12345678-1234-1234-1234-123456789012"

        .EXAMPLE
        Get-CAIQUserMemberOf -UserId "12345678-1234-1234-1234-123456789012" -Recursive

        .EXAMPLE
        Get-MgUser -UserId "12345678-1234-1234-1234-123456789012" | Get-CAIQUserMemberOf

        .INPUTS
        System.String
        System.String[]
        System.Automation.SwitchParameter        

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param (
        [Parameter(
            Mandatory=$true,Position=0,ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
                
        )]
        [Alias(
            "Id","UserPrincipalName","UPN"
            
        )]
        [string]$UserId,
        [Parameter(Mandatory=$false)]
        [string[]]$Select = @(
            "displayName","id","mail","groupTypes"
            
        ),
        [Parameter(Mandatory=$false)]
        [switch]$Recursive,
        [Parameter(Mandatory=$false)]
        [string]$Expand,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Beta","v1.0")]
        [string]$ApiVersion = "v1.0"
    
    )
    Begin {
    } Process {
        # Get the Microsoft Graph endpoint, if not already set
        If (!$script:graph_endpoint) {
            $script:graph_endpoint = Get-CAIQGraphEndpoint
        
        }
        
        # Set the endpoint
        $end_point = If ($recursive) {
            "transitiveMemberOf"
        
        } Else {
            "memberOf"
        
        }
        # Invoke-MgGraphRequest parameters
        $invoke_mg_params = @{}
        $invoke_mg_params["Uri"] = "$($script:graph_endpoint)/$apiVersion/users/$userId/$($end_point)/microsoft.graph.group?`$count=true&`$select=$($select -join ',')&`$expand=$($expand)"
        $invoke_mg_params["Method"] = "GET"
        $invoke_mg_params["Headers"] = @{}
        $invoke_mg_params["Headers"]["ConsistencyLevel"] = "eventual"
        $invoke_mg_params["OutputType"] = "PSObject"

        Try {
            Do {
                # Invoke-MgGraphRequest
                $r = (Invoke-MgGraphRequest @invoke_mg_params)
                
                # Return the results
                $r.value
                
                # Set the next link
                $invoke_mg_params["Uri"] = $r."@odata.nextLink"
            
            # Looping through the results until there are no more results
            } Until (!$r."@odata.nextLink")
        } Catch {
            Write-Error -Message $_

        }
    } End {

    }
}