class GraphParameterProcessor {
    <#
        .SYNOPSIS
        A utility class for processing PowerShell parameters for Graph API requests.
        
        .DESCRIPTION
        This class provides methods to handle common parameter processing tasks like
        filtering bound parameters and creating request bodies for Graph API calls.
    
    #>
    
    # Static method to transform property names to Graph API format (camelCase)
    static [string]TransformToGraphKey([string]$propertyName) {
        # Convert PascalCase to camelCase for Graph API
        if ($propertyName.Length -eq 0) { 
            return $propertyName 
        
        }
        return $propertyName.Substring(0,1).ToLower() + $propertyName.Substring(1)
    
    }
    
    # Static method to process values for Graph API compatibility
    static [object]ProcessValueForGraph([object]$value) {
        switch ($value.GetType().Name) {
            "DateTime" { 
                return $value.ToString("yyyy-MM-ddTHH:mm:ss.fffZ") 
            }
        }
        return $value
    }

    # Static method to filter parameters and create a request body
    static [hashtable]CreateRequestBody([hashtable]$params, [hashtable]$defaultParams) {
        # Build the exclusion list
        $exclusions = @(
            #$defaultParams.Keys
            [System.Management.Automation.PSCmdlet]::CommonParameters
            [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
            "ApiVersion",
            "PassThru",
            "AdditionalProperties"
        )

        # Add default parameters to the exclusion list if they exist
        If ($defaultParams.Keys) {
            $exclusions += $defaultParams.Keys
        
        }
        
        # Process each parameter
        foreach ($key in $params.Keys) {
            if ($key -notin $exclusions) {
                $value = $params[$key]

                # Transform the key to Graph API format (camelCase)
                $graph_key = [GraphParameterProcessor]::TransformToGraphKey($key)
                
                # Handle type conversions (DateTime, etc.)
                $processed_value = [GraphParameterProcessor]::ProcessValueForGraph($value)
                
                # Add the processed value to the default parameters
                $defaultParams[$graph_key] = $processed_value
            
            }
        } 
        # Return the default parameters
        return $defaultParams
    }
 }