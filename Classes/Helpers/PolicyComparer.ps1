class PolicyComparer {

    # Private field for the regex to exclude certain properties from comparison.
    hidden [regex]$ExcludeRegex = "(?i)(modifiedDateTime|createdDateTime|@odata\.context)"

    # Constructor for the class.
    PolicyComparer() {
    }

    # Method to check if a property's value is a nested object.
    hidden [bool]IsNestedObject([object]$value) {
        # Check if the value is a dictionary or a PSObject
        if ($value -is [System.Collections.IDictionary] -or $value -is [PSObject]) {
            return $true
        
        }
        # If the value is not a dictionary or a PSObject, return false
        return $false
    
    }

    # Method to compare two arrays to see if they are different.
    hidden [bool]CompareArrays([array]$referenceArray, [array]$differenceArray) {
        # Compare the two arrays
        $comparison_result = Compare-Object -ReferenceObject $referenceArray -DifferenceObject $differenceArray -PassThru
        
        # If the comparison result is not null, return true
        if ($comparison_result) {
            return $true
        
        }
        # If the comparison result is null, return false
        return $false
    
    }

    # Method to compare two values of any type to see if they are different.
    hidden [bool]CompareValues([object]$referenceValue, [object]$differenceValue) {
        # Check for differences in existence (one is null, the other is not)
        if ((!$referenceValue -and $differenceValue) -or ($referenceValue -and !$differenceValue)) {
            return $true
        
        } elseif ($referenceValue -and $differenceValue) {
            # If both values are arrays, use the array comparison helper
            if ($referenceValue -is [array] -and $differenceValue -is [array]) {
                return $this.CompareArrays($referenceValue, $differenceValue)
            
            # If both values are non-array types, use a simple string comparison
            } elseif ("$referenceValue" -ne "$differenceValue") {
                return $true
            
            }
        }
        # If none of the above conditions are met, the values are the same
        return $false
    
    }

    # Method to flatten a nested PSCustomObject into a single-level object with dot-notation keys.
    hidden [pscustomobject]FlattenObject([object]$inputObject, [string]$prefix) {
        # Create a new PSObject to store the flattened object
        $flat_object = New-Object -TypeName PSObject

        # If the input object is null, return the empty PSObject
        if (!$inputObject) {
            return $flat_object
        
        }

        # Iterate over each property of the input object
        foreach ($property in $inputObject.PSObject.Properties) {
            # Create a key for the property
            $key = $null
            if ($prefix) {
                $key = "$prefix.$($property.Name)"
            
            } else {
                $key = $property.Name
            
            }

            # If the property is a nested object, recursively flatten it
            if ($this.IsNestedObject($property.Value)) {    
                # Recursively flatten the nested object
                $nested_object = $this.FlattenObject($property.Value, $key)

                # Add each nested property to the flat object
                foreach ($nested_property in $nested_object.PSObject.Properties) {
                    $flat_object | Add-Member -MemberType NoteProperty -Name $nested_property.Name -Value $nested_property.Value -Force
                
                }
            } else {
                # Add the property to the flat object, if it's not a nested object
                $flat_object | Add-Member -MemberType NoteProperty -Name $key -Value $property.Value -Force
            
            }
        }
        # Return the flattened object
        return $flat_object
    
    }

    # Public method to compare two policy objects and return a list of their differences.
    [System.Collections.Generic.List[PSCustomObject]]GetDifferences([object]$referenceObject, [object]$differenceObject) {
        # Create a new list to store the differences
        $differences_list = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Flatten the reference and difference objects to handle nested properties
        $flattened_reference = $this.FlattenObject($referenceObject, $null)
        $flattened_difference = $this.FlattenObject($differenceObject, $null)

        # Get all unique property names from both flattened objects
        $all_properties = ($flattened_reference.PSObject.Properties.Name + $flattened_difference.PSObject.Properties.Name) | Select-Object -Unique

        # Iterate over each property name
        foreach ($property_name in $all_properties) {
            # If the property name matches the exclude regex, skip it
            if ($property_name -match $this.ExcludeRegex) {
                continue
            
            }

            # Get the value of the property from the reference and difference objects
            $reference_value = $flattened_reference.PSObject.Properties[$property_name].Value
            $difference_value = $flattened_difference.PSObject.Properties[$property_name].Value

            # Use the helper method to determine if the values are different
            if ($this.CompareValues($reference_value, $difference_value)) {
                # Create a new ordered hashtable to store the change details
                $change_details = [ordered]@{}
                $change_details['FullPath'] = $property_name
                $change_details['PropertyName'] = ($property_name -split '\.')[-1]
                $change_details['OldValue'] = $reference_value
                $change_details['NewValue'] = $difference_value

                # Add the change details to the list as a PSCustomObject
                $differences_list.Add([PSCustomObject]$change_details)
            
            }
        }
        # Return the list of differences
        return $differences_list
    
    }
}