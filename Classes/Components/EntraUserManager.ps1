class EntraUserManager {
    <#
        .SYNOPSIS
        Manage users in Microsoft Entra

        .DESCRIPTION
        This class manages users in Microsoft Entra.

        .PARAMETER GraphRequestClient
        The GraphRequestClient object.

        .PARAMETER Users
        The list of users.
    
    #>
    [GraphRequestClient]$GraphRequestClient
    [System.Collections.Generic.List[object]]$Users

    # Constructor
    EntraUserManager([GraphRequestClient]$GraphRequestClient) {
        $this.Users = [System.Collections.Generic.List[object]]::new()
        $this.GraphRequestClient = $GraphRequestClient
    
    }
    #region Get user    
    # Method to get a user by id
    [void]GetUser([string]$userId,[hashtable]$queryParams) {
        $this.GetUsers("id eq '$userId'", $queryParams)
    
    }

    # Method to get users by filter
    [void]GetUsers([string]$filter,[hashtable]$queryParams) {
        # Get the users
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("users", $null, $filter, $queryParams)

        # Update the users list
        $this.UpdateUsers($results)
            
    }

    #endregion

    #region User enable/disable
    # Disable a user
    [void]DisableUser([string]$userId) {
        # Build the body
        $body = $this.SetEnableUserParams($false) 

        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPatchRequest("users", $userId, $body)

    }

    # Enable a user
    [void]EnableUser([string]$userId) {
        # Set the request parameters
        $body = $this.SetEnableUserParams($true) 

        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPatchRequest("users", @($userId), $body)
        

    }

    # Revoke a user's sign in sessions
    [void]RevokeUserSignInSessions([string]$userId) {
        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPostRequest("users", @($userId, "revokeSignInSessions"), $null)
        
    }

    # Method to set the enable user parameters
    hidden [hashtable]SetEnableUserParams([bool]$enabled) {
        $body = @{}
        $body["accountEnabled"] = $enabled
        Return $body
    
    }

    #endregion

    #region Create and remove users
    # Method to remove a user (place this in the EntraUserManager class)
    [void]RemoveUser([string]$userId) {
        # Invoke the request
        $this.GraphRequestClient.InvokeGraphDeleteRequest("users", $userId)
        
    }

    # Method to restore a user
    [void]RestoreUser([string]$userId) {
        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPostRequest("directory/deletedItems", @($userId, "restore"), $null)
        
    }

    # Method to create a new user
    [object]CreateUser([hashtable]$userParams) {
        return $this.GraphRequestClient.InvokeGraphPostRequest("users", $null, $userParams)
    
    }

    # Method to update a user in Microsoft Graph
    [object]UpdateUser([string]$userId, [hashtable]$updateParams) {
        return $this.GraphRequestClient.InvokeGraphPatchRequest("users", @($userId), $updateParams)
    
    }

    #endregion

    #region Client-side data management
    # Method to show the users
    [object[]]ShowUsers() {
        Return $this.Users
    
    }

    # Method to update the users list
    hidden [void]UpdateUsers([object[]]$users) {
        Foreach ($item in $users) {
            $this.Users.Add($item)
        
        }
    }

    #endregion
}