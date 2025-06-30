class EntraCAPolicyManager {
    [GraphRequestClient]$GraphRequestClient
    [System.Collections.Generic.List[object]]$Policies

    EntraCAPolicyManager([GraphRequestClient]$GraphRequestClient) {
        $this.Policies = [System.Collections.Generic.List[object]]::new()
        $this.GraphRequestClient = $GraphRequestClient

    }

    #region Get Policies
    # Method to get a policy by ID
    [void]GetPolicy([string]$policyId, [hashtable]$queryParams) {
        # Validate if the policy ID is a GUID if not, use the display name to filter
        If (![GraphRequestClient]::IsGuid($policyId)) {
            $filter = "displayName eq '$policyId'"

        } Else {
            $filter = "id eq '$policyId'"

        }
        # Get the policy
        $this.GetPolicies($filter, $queryParams)

    }

    # Method to get policies by filter
    [void]GetPolicies([string]$filter, [hashtable]$queryParams) {
        # Invoke the request
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("identity/conditionalAccess/policies",$null,$filter,$queryParams)

        # Update the policies
        $this.UpdatePolicies($results)

    }

    #endregion

    #region Modify Policies
    # Method to enable a policy
    [void]EnablePolicy([string]$policyId) {
        $this.SetPolicyState($policyId, "enabled")

    }

    # Method to disable a policy
    [void]DisablePolicy([string]$policyId) {
        $this.SetPolicyState($policyId, "disabled")

    }

    # Method to enable report-only mode
    [void]EnableForReportingButNotEnforced([string]$policyId) {
        $this.SetPolicyState($policyId, "enabledForReportingButNotEnforced")

    }

    # Method to delete a policy
    [void]RemovePolicy([string]$policyId) {
        # Invoke the request
        $this.GraphRequestClient.InvokeGraphDeleteRequest("identity/conditionalAccess/policies/$policyId",$null)
        
    }

    # Method to set the state of a policy
    hidden [void]SetPolicyState([string]$policyId, [string]$state) {
        # Validate the state
        If ($this.ValidateState($state)) {
            $body = @{state = $state} 
        } Else {
            Throw "Invalid state '$state'. Valid states are 'enabled', 'disabled', 'enabledForReportingButNotEnforced'."

        }

        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPatchRequest("identity/conditionalAccess/policies/$policyId",$null,$body)

    }

    # Method to validate the state
    [bool]ValidateState([string]$state) {
        If ($state -in @("enabled", "disabled", "enabledForReportingButNotEnforced")) {
            Return $true

        } Else {
            Return $false

        }
    }

    #endregion

    #region Output
    # Method to show the policies
    [object[]]ShowPolicies() {
        return $this.Policies

    }

    # Method to update the policies
    hidden [void]UpdatePolicies([object[]]$policies) {
        foreach ($item in $policies) {
            $this.Policies.Add($item)

        }
    }

    #endregion
}
