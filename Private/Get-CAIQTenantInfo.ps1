Function Get-CAIQTenantInfo {
    <#
        .SYNOPSIS
        Gets the current tenant information from Microsoft Graph.

        .DESCRIPTION
        This function retrieves the organization details for the current tenant using Microsoft Graph API.

        .OUTPUTS
        System.Object
    
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param()
    # Get the Microsoft Graph endpoint, if not already set
    If (!$script:graph_endpoint) {
        $script:graph_endpoint = Get-CAIQGraphEndpoint
    
    }

    # Invoke-MgGraphRequest parameters
    $invoke_mg_params = @{}
    $invoke_mg_params["Uri"] = "$script:graph_endpoint/v1.0/organization"
    $invoke_mg_params["Method"] = "GET"
    $invoke_mg_params["OutputType"] = "PSObject"
    $invoke_mg_params["ErrorAction"] = "Stop"

    try {
        # Get the tenant information
        $tenant = Invoke-MgGraphRequest @invoke_mg_params
        $tenant.Value
    
    } catch {
        Write-Warning "Failed to retrieve tenant information: $_"
        $null

    }
}