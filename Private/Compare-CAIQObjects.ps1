Function Compare-CAIQObjects {
    <#
        .SYNOPSIS
        This is a function that compares two conditional access policy objects recursively and returns the differences.

        .DESCRIPTION
        This is a function that compares two conditional access policy objects and returns the differences.

        .PARAMETER ReferenceObject
        The reference object to compare.

        .PARAMETER DifferenceObject
        The difference object to compare.

        .PARAMETER Exclude
        The properties to exclude from the comparison.

        .INPUTS
        System.Object

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [object]$ReferenceObject,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [object]$DifferenceObject,
        [Parameter(DontShow=$true)]
        [regex]$Exclude = "(?i)(modifieddatetime|createddatetime|@odata\.context)"
    )
    Begin {
        # Initialize the differences list
        $differences = [System.Collections.Generic.List[PSCustomObject]]::new()
    
    } Process {
        # Flatten the reference and difference objects
        $flattened_reference = ConvertTo-CAIQFlatObject -InputObject $ReferenceObject
        $flattened_difference = ConvertTo-CAIQFlatObject -InputObject $DifferenceObject

        # Get all properties from both objects
        $all_properties = $flattened_reference.PSObject.Properties.Name + $flattened_difference.PSObject.Properties.Name | Select-Object -Unique
        
        foreach ($property_name in $all_properties) {
            # Initialize the is_different variable
            $is_different = $false

            # Skip the ModifiedDateTime property
            if ($property_name -match $exclude) { 
                continue 
            
            }
 
            # Get the property values from both objects
            $reference_value = $flattened_reference.$property_name
            $difference_value = $flattened_difference.$property_name

            # If the reference value is null and the difference value is not null, then the policy has been modified
            if ($null -eq $reference_value -and $null -ne $difference_value) {
                $is_different = $true
            
            # If the reference value is not null and the difference value is null, then the policy has been modified
            } Elseif ($null -ne $reference_value -and $null -eq $difference_value) {
                $is_different = $true
            
            # If the reference value and the difference value are not null, then compare the values
            } ElseIf ($null -ne $reference_value -and $null -ne $difference_value) {
                # If the reference value and the difference value are arrays, then compare the arrays
                if ($reference_value -is [array] -and $difference_value -is [array]) {
                    # If the arrays are different, then the policy has been modified
                    if (Compare-Object $reference_value $difference_value) {
                        $is_different = $true
                    
                    }
                # If the reference value and the difference value are not arrays, then compare the values
                } Elseif ($reference_value -ne $difference_value) {
                    $is_different = $true
                
                }
            }
            # If the policy has been modified, then add the difference to the list
            if ($is_different) {
                $short_name = $property_name -split '\.' | Select-Object -Last 1
                $obj = [ordered]@{}
                $obj['FullPath'] = $property_name
                $obj['PropertyName'] = $short_name
                $obj['OldValue'] = $reference_value
                $obj['NewValue'] = $difference_value
                $differences.Add([PSCustomObject]$obj)

            }
        }
    } End {
        # Return the differences
        $differences
    
    }
}