class EntraDirectoryObjectResolver {

    # Private client for making Graph API requests.
    hidden [GraphRequestClient]$GraphClient

    # Private cache to store resolved IDs to avoid redundant API calls within a single run.
    hidden [hashtable]$ResolvedCache

    # Constructor for the class.
    DirectoryObjectResolver([GraphRequestClient]$graphClient) {
        $this.GraphClient = $graphClient
        $this.ResolvedCache = @{}
    
    }

    # Method to get the correct Graph API endpoint based on a property name.
    hidden [string]GetEndpoint([string]$propertyName) {
        # Use a switch statement to return the correct endpoint for a given property.
        switch -regex ($propertyName) {
            "users" {
                return "users"
            
            } "groups" {
                return "groups"
            
            } "applications" {
                return "servicePrincipals"
            
            } "roles" {
                return "roleManagement/directory/roleDefinitions"
            
            } 
        }
        return $null
    
    }

    # Method to resolve an array of IDs to an array of display names.
    hidden [string[]]ResolveToDisplayName([string[]]$ids, [string]$endpoint) {
        # Create a new list to store the resolved display names.
        $resolved_names = [System.Collections.Generic.List[string]]::new()

        # If the input array of IDs is null or empty, return an empty array.
        if (!$ids) {
            return @()
        
        }

        # Iterate over each ID to resolve it.
        foreach ($id in $ids) {
            # Check the cache first to see if this ID has already been resolved.
            if ($this.ResolvedCache.ContainsKey($id)) {
                [void]$resolved_names.Add($this.ResolvedCache[$id])
                continue
            
            }

            # If not in the cache, attempt to resolve it via the Graph API.
            try {
                # The specific query parameters to select only the displayName.
                $query_params = @{}
                $query_params['$select'] = 'displayName'

                # Invoke the Graph API request using the client's method signature.
                $result = $this.GraphClient.InvokeGraphGetRequest($endpoint, @($id), $null, $query_params)

                # If a result is returned, add the display name to the list and the cache.
                if ($result) {
                    [void]$resolved_names.Add($result.displayName)
                    $this.ResolvedCache[$id] = $result.displayName
                
                } else {
                    # Handle cases where the ID is valid but no object is returned (likely deleted).
                    $deleted_name = "[DELETED] $id"
                    [void]$resolved_names.Add($deleted_name)
                    $this.ResolvedCache[$id] = $deleted_name
                
                }
            } catch {
                # If an error occurs (e.g., 404 Not Found), treat the object as deleted.
                $deleted_name = "[DELETED] $id"
                [void]$resolved_names.Add($deleted_name)
                $this.ResolvedCache[$id] = $deleted_name
            
            }
        }
        # Return the final array of resolved names.
        return [string[]]$resolved_names
    
    }

    # Public method to process a differences object and resolve all IDs to display names.
    [System.Collections.Generic.List[PSCustomObject]]ResolveObject([System.Collections.Generic.List[PSCustomObject]]$differences) {
        # Regex to identify properties that contain object IDs that need to be resolved.
        $property_regex = "(?i)(include|exclude)(Users|Groups|Applications|Roles)"

        # Iterate over each change detail in the differences object.
        foreach ($change in $differences) {
            # Check if the property name is one that we need to resolve.
            if ($change.PropertyName -match $property_regex) {
                # Get the correct API endpoint for this property type.
                $endpoint = $this.GetEndpoint($change.PropertyName)
                if (!$endpoint) {
                    continue
                
                }

                # Resolve the IDs in the OldValue and NewValue properties.
                $old_value_names = $this.ResolveToDisplayName($change.OldValue, $endpoint)
                $new_value_names = $this.ResolveToDisplayName($change.NewValue, $endpoint)

                # Update the change object with the human-readable names, joined as a string for display.
                $change.OldValue = $old_value_names -join ", "
                $change.NewValue = $new_value_names -join ", "
            
            }
        }
        # Return the modified differences object.
        return $differences
    
    }
}