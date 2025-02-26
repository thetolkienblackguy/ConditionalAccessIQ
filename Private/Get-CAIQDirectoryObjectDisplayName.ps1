function Get-CAIQDirectoryObjectDisplayName {
    <#
        .SYNOPSIS
        Get the display name of a directory object from Microsoft Graph

        .DESCRIPTION
        This function gets the display name of a directory object from Microsoft Graph.

        .PARAMETER Endpoint 
        The endpoint to call Microsoft Graph.

        .PARAMETER DirectoryObjectId
        The ID of the directory object to get the display name for.

        .INPUTS
        System.String

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([system.string])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        [Parameter(Mandatory=$true)]
        [string]$DirectoryObjectId
    
    )
    Begin {
        # Get the Microsoft Graph endpoint, if not already set
        If (!$script:graph_endpoint) {
            $script:graph_endpoint = Get-CAIQGraphEndpoint
        
        }

        # Invoke-MgGraphRequest parameters
        $invoke_mg_params = @{}
        $invoke_mg_params["Method"] = "GET"
        $invoke_mg_params["OutputType"] = "PSObject"

        # Regex to determine if the directoryObjectId is a GUID
        $guid_regex = "^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$"

        # URI to call Microsoft Graph
        $uri = "$script:graph_endpoint/v1.0{0}{1}"
    } Process {
        # If the directoryObjectId is a GUID
        If ($directoryObjectId -match $guid_regex) {
            # If the endpoint is for applications set the filter to look for the directoryObjectId as an appId
            If ($endpoint -eq "/servicePrincipals") {
                $filter = "?`$filter=appId eq '$($directoryObjectId)'"
            
            #If the endpoint is not for applications set the filter to look for the directoryObjectId as an ID
            } Else {
                $filter = "?`$filter=id eq '$($directoryObjectId)'"
            
            }
        } Else {
            # If the directoryObjectId is not a GUID return it as is
            return $directoryObjectId
        
        }
        # Call Microsoft Graph and return the display name
        Try {
            $r = (Invoke-MgGraphRequest @Invoke_mg_params -Uri ($uri -f $endpoint, $filter)).Value.DisplayName
            $r
        
        } Catch {
            $directoryObjectId
        
        }
    } End {

    }
}