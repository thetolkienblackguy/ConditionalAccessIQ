class EntraDirectoryObjectManager {
    [GraphRequestClient]$GraphRequestClient
    [System.Collections.Generic.List[object]]$DirectoryObjects

    EntraDirectoryObjectManager([GraphRequestClient]$GraphRequestClient) {
        $this.DirectoryObjects = [System.Collections.Generic.List[object]]::new()
        $this.GraphRequestClient = $GraphRequestClient
    
    }
    # Method to get a directory object by id
    [void]GetDirectoryObject([string]$directoryObjectId,[hashtable]$queryParams) {
        $result = $this.GraphRequestClient.InvokeGraphGetRequest("directoryObjects", $directoryObjectId, $null, $queryParams)
        
        # Update the directory objects list
        $this.UpdateDirectoryObjects($result)
    
    }

    # Method to get directory objects by filter
    [void]GetDirectoryObjects([string]$filter,[hashtable]$queryParams) {
        # Get the directory objects
        $results = $this.GraphRequestClient.InvokeGraphGetRequest("directoryObjects", $null, $filter, $queryParams)

        # Update the directory objects list
        $this.UpdateDirectoryObjects($results)
            
    }

    #endregion

    #region Create and remove directory objects
    # Method to remove a directory object
    [void]RemoveDirectoryObject([string]$directoryObjectId) {
        # Invoke the request
        $this.GraphRequestClient.InvokeGraphDeleteRequest("directoryObjects", $directoryObjectId)
        
    }

    # Method to restore a directory object
    [void]RestoreDirectoryObject([string]$directoryObjectId) {
        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPostRequest("directory/deletedItems", @($directoryObjectId, "restore"), $null)
        
    }

    #endregion

    #region Client-side data management

    #endregion
 
    #region Show Directory Objects
    [object[]]ShowDirectoryObjects() {
        Return $this.DirectoryObjects
    
    }

    # Method to update the directory objects list
    hidden [void]UpdateDirectoryObjects([object[]]$directoryObjects) {
        Foreach ($item in $directoryObjects) {
            $this.DirectoryObjects.Add($item)
        
        }
    }

    #endregion

}