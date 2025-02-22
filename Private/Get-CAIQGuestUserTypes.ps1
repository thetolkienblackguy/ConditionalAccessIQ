Function Get-CAIQGuestUserTypes {
    <#
        .SYNOPSIS
        Get the guest user types for a given value
        
        .DESCRIPTION
        This function takes a value and returns the guest user types for that value
        
        .PARAMETER Value
        The value to get the guest user types for
        
        .EXAMPLE
        Get-CAIQGuestUserTypes -Value 1
        Returns "Local guest users"

        .EXAMPLE
        Get-CAIQGuestUserTypes -Value 11
        Returns "Local guest users", "B2B Collaboration guest users", "B2B Direct connect users"

        .EXAMPLE
        Get-CAIQGuestUserTypes -Value 100
        Returns "Unknown external user type"
    
        .INPUTS
        System.Int32

        .OUTPUTS
        System.Collections.Generic.List[System.String]

    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.String]])]
    param (
        [Parameter(Mandatory=$true)]
        [int]$Value
    
    )
    Begin {
        # Define the guest user type mappings
        $guest_types = @{}
        $guest_types["1"] = "Local guest users"
        $guest_types["2"] = "B2B Collaboration guest users"
        $guest_types["4"] = "B2B Collaboration members users"
        $guest_types["8"] = "B2B Direct connect users"
        $guest_types["16"] = "Other external users"
        $guest_types["32"] = "Service provider users"

        # Initialize results list
        $results = [System.Collections.Generic.List[string]]::new()

        # Calculate max valid value
        $valid_flags = $guest_types.Keys
        $max_value = ($valid_flags | Measure-Object -Sum).Sum
    
    } Process {
        # Check for invalid values
        if ($value -le 0 -or $value -gt $max_value) {
            [void]$results.Add($value.ToString())
            return $results
        
        }

        # Return null for value of 0
        if ($value -eq 0) {
            [void]$results.Add($null)
            return $results
        
        }

        # Check for invalid combinations
        $remaining = $value
        foreach ($flag in $valid_flags | Sort-Object -Descending) {
            if ($remaining -band $flag) {
                $remaining = $remaining - $flag
            
            }
        }
        # If there are any remaining bits, the value is invalid
        if ($remaining -ne 0) {
            [void]$results.Add($value.ToString())
            return $results
        
        }

        # If we get here, process valid flags
        foreach ($flag in $guest_types.Keys | Sort-Object) {
            if ($value -band $flag) {
                [void]$results.Add($guest_types[$flag])
            
            }
        }
        # Return the results
        return $results
    
    } End {    
    }
}