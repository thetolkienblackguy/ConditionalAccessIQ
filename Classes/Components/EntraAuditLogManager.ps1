class EntraAuditLogManager {
    [GraphRequestClient]$GraphRequestClient
    [System.Collections.Generic.List[object]]$SignInLogs
    [System.Collections.Generic.List[object]]$AuditLogs
    [System.Collections.Generic.List[object]]$ProvisioningLogs

    # Constructor
    EntraAuditLogManager([GraphRequestClient]$GraphRequestClient) {
        $this.SignInLogs = [System.Collections.Generic.List[object]]::new()
        $this.AuditLogs = [System.Collections.Generic.List[object]]::new()
        $this.ProvisioningLogs = [System.Collections.Generic.List[object]]::new()
        $this.GraphRequestClient = $GraphRequestClient
    
    }

    #region Server-side data management
    # Method to get sign-in logs
    [void]GetSignInLogs([string]$filter, [hashtable]$queryParams) {
        # Get the sign-in logs
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("auditLogs/signIns", $null, $filter, $queryParams)
        
        # Update the sign-in logs
        $this.UpdateSignInLogs($results)
    
    }

    # Method to get audit logs
    [void]GetAuditLogs([string]$filter, [hashtable]$queryParams) {
        # Get the audit logs
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("auditLogs/directoryAudits", $null, $filter, $queryParams)
        
        # Update the audit logs
        $this.UpdateAuditLogs($results)
    }

    # Method to get provisioning logs
    [void]GetProvisioningLogs([string]$filter, [hashtable]$queryParams) {
        # Get the provisioning logs
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("auditLogs/provisioning", $null, $filter, $queryParams)
        
        # Update the provisioning logs
        $this.UpdateProvisioningLogs($results)
    }
    
    #endregion

    #region Client-side data management
    # Method to show sign-in logs
    [object[]]ShowSignInLogs() {
        Return $this.SignInLogs
    
    }

    # Method to update the sign-in logs
    hidden [void]UpdateSignInLogs([object[]]$logs) {
        Foreach ($item in $logs) {
            $this.SignInLogs.Add($item)
        
        }
    }

    # Method to show audit logs
    [object[]]ShowAuditLogs() {
        Return $this.AuditLogs
    
    }

    # Method to update the audit logs
    hidden [void]UpdateAuditLogs([object[]]$logs) {
        Foreach ($item in $logs) {
            $this.AuditLogs.Add($item)
        
        }
    }

    # Method to show provisioning logs
    [object[]]ShowProvisioningLogs() {
        Return $this.ProvisioningLogs
    }

    # Method to update the provisioning logs
    hidden [void]UpdateProvisioningLogs([object[]]$logs) {
        Foreach ($item in $logs) {
            $this.ProvisioningLogs.Add($item)
        
        }
    }
    #endregion
}