Function Get-CAIQDirectoryAuditLog {
    <#
        .SYNOPSIS
        This is a helper function that gets the modified by for a policy from the Entra ID audit logs.

        .DESCRIPTION
        This is a helper function that gets the modified by for a policy from the Entra ID audit logs.

        .PARAMETER PolicyId
        The ID of the policy.

        .PARAMETER ApiVersion
        The API version to use.

        .PARAMETER StartDate
        The start date to filter by.

        .PARAMETER EndDate
        The end date to filter by.

        .INPUTS
        System.String

        .OUTPUTS
        System.String

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$PolicyId,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Update", "Delete", "Add")]
        [string]$Action = "Update",
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            $utc_regex = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
            if ($_ -notmatch $utc_regex) {
                throw "StartDate must be in UTC format (yyyy-MM-ddTHH:mm:ssZ)"
            }
            return $true
        
        })]
        [string]$StartDate = (Get-Date).AddDays(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"),
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            $utc_regex = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
            if ($_ -notmatch $utc_regex) {
                throw "EndDate must be in UTC format (yyyy-MM-ddTHH:mm:ssZ)"
            }
            if ([DateTime]::ParseExact($_, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture) -lt [DateTime]::ParseExact($StartDate, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)) {
                throw "EndDate cannot be before StartDate"
            
            }
            return $true
        
        })]
        [string]$EndDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    )
    # Build the filter
    $filter = "ActivityDisplayName eq '$action conditional access policy' and targetResources/any(t:t/id eq '$policyId') and ActivityDateTime gt $startDate and ActivityDateTime lt $endDate"
    $invoke_mg_params = @{}
    $invoke_mg_params['Uri'] = "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?`$filter=$filter"
    $invoke_mg_params['Method'] = "GET"
    $invoke_mg_params['OutputType'] = "PSObject"

    # Get and return the audit logs for the policy within the date range
    (Invoke-MgGraphRequest @invoke_mg_params).Value

}
