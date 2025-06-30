class EntraGroupManager {
    [GraphRequestClient]$GraphRequestClient
    [System.Collections.Generic.List[object]]$Groups
    [System.Collections.Generic.List[object]]$GroupMembers
    [System.Collections.Generic.List[object]]$GroupOwners

    EntraGroupManager([GraphRequestClient]$GraphRequestClient) {
        $this.Groups = [System.Collections.Generic.List[object]]::new()
        $this.GroupMembers = [System.Collections.Generic.List[object]]::new()
        $this.GroupOwners = [System.Collections.Generic.List[object]]::new() 
        $this.GraphRequestClient = $GraphRequestClient
    
    }

    #region Get Groups and members
    # Method to get a group by id
    [void]GetGroup([string]$groupId,[hashtable]$queryParams) {
        # If the directory role is a GUID, use the ID filter
        If ([GraphRequestClient]::IsGuid($groupId)) {
            $filter = "id eq '$groupId'"

        # If the directory role is a display name, use the display name filter
        } Else {
            $filter = "displayName eq '$groupId'"
        
        }
        $this.GetGroups($filter, $queryParams)
    
    }

    # Method to get groups by filter
    [void]GetGroups([string]$filter,[hashtable]$queryParams) {
        # Get the groups
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("groups", $null, $filter, $queryParams)

        # Update the groups list
        $this.UpdateGroups($results)
    
    }

    # Method to get group members/owners
    [void]GetGroupMembers([string]$groupId,[hashtable]$queryParams,[string]$odataType) {
        # Get the group. This allows the caller to use the groupId or displayName.
        $this.GetGroup($groupId, $null)

        $group = $this.Groups[0]

        # Set the request parameters
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("groups/$($group.Id)/members", $odataType, $null, $queryParams)

        # Update the group members list
        $this.UpdateGroupMembers($results)
    
    }

    # Method to get the transitive members of a group
    [void]GetGroupTransitiveMembers([string]$groupId,[hashtable]$queryParams,[string]$odataType) {
        # Get the group
        $this.GetGroup($groupId, $null)
        $group = $this.Groups[0]

        # Set the request parameters
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("groups/$($group.Id)/transitiveMembers", $odataType, $null, $queryParams)

        # Update the group members list
        $this.UpdateGroupMembers($results)
    
    }

    # Method to get the owners of a group
    [void]GetGroupOwners([string]$groupId,[hashtable]$queryParams) {
        # Get the group
        $this.GetGroup($groupId, $null)
        $group = $this.Groups[0]

        # Set the request parameters
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("groups/$($group.Id)/owners", $null, $null, $queryParams)

        # Update the group owners list
        $this.UpdateGroupOwners($results)
    
    }

    #endregion

    #region Add and remove directory assignments
    # Generic method to add a directory object to a relationship
    [void]AddDirectoryAssignment([string]$endpoint,[string]$assignmentId,[string]$relationshipType,[string]$directoryObjectId) {
        # Build the body
        $body = @{"@odata.id" = $this.GraphRequestClient.BuildGraphUri("directoryObjects", $directoryObjectId, $null, $false)} 

        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPostRequest("$endpoint/$assignmentId/$relationshipType", "`$ref", $body)
    
    }

    # Generic method to remove a directory object from a relationship
    [void]RemoveDirectoryAssignment([string]$endpoint,[string]$assignmentId,[string]$relationshipType,[string]$directoryObjectId) {
        # Invoke the delete request
        $this.GraphRequestClient.InvokeGraphDeleteRequest("$endpoint/$assignmentId/$relationshipType/$directoryObjectId", "`$ref")
    
    }

    # Method to add a member to a group (using the generic method)
    [void]AddGroupMember([string]$groupId,[string]$directoryObjectId) {
        $this.AddDirectoryAssignment("groups", $groupId, "members", $directoryObjectId)
    
    }

    # Method to remove a member from a group (using the generic method)
    [void]RemoveGroupMember([string]$groupId,[string]$directoryObjectId) {
        $this.RemoveDirectoryAssignment("groups",$groupId,"members",$directoryObjectId)
    
    }

    # Method to add an owner to a group (using the generic method)
    [void]AddGroupOwner([string]$groupId,[string]$directoryObjectId) {
        $this.AddDirectoryAssignment("groups",$groupId, "owners",$directoryObjectId)
    
    }

    # Method to remove an owner from a group (using the generic method)
    [void]RemoveGroupOwner([string]$groupId,[string]$directoryObjectId) {
        $this.RemoveDirectoryAssignment("groups", $groupId, "owners", $directoryObjectId)
    
    }
    #endregion

    #region Create, remove update groups
    # Method to create a group
    [object]CreateGroup([hashtable]$groupParams) {
        return $this.GraphRequestClient.InvokeGraphPostRequest("groups", $null, $groupParams)
    
    }

    # Method to remove a group
    [void]RemoveGroup([string]$groupId) {
        $this.GraphRequestClient.InvokeGraphDeleteRequest("groups", $groupId)
    
    }
    
    # Method to update a group
    [object]UpdateGroup([string]$groupId, [hashtable]$groupParams) {
        return $this.GraphRequestClient.InvokeGraphPatchRequest("groups", $groupId, $groupParams)
    
    }
    #endregion

    #region Client-side data management
    # Method to show the groups
    [object[]]ShowGroups() {
        Return $this.Groups
    
    }

    # Method to update the groups list
    hidden [void]UpdateGroups([object[]]$groups) {
        Foreach ($item in $groups) {
            $this.Groups.Add($item)
        
        }
    }

    # Method to show the group members
    [object[]]ShowGroupMembers() {
        Return $this.GroupMembers
    
    }

    # Method to update the group members list
    hidden [void]UpdateGroupMembers([object[]]$groupMembers) {
        Foreach ($item in $groupMembers) {
            $this.GroupMembers.Add($item)
        
        }
    }

    # Method to show the group owners
    [object[]]ShowGroupOwners() {
        Return $this.GroupOwners
    
    }

    # Method to update the group owners list
    hidden [void]UpdateGroupOwners([object[]]$groupOwners) {
        Foreach ($item in $groupOwners) {
            $this.GroupOwners.Add($item)
        
        }
    }
    #endregion

}