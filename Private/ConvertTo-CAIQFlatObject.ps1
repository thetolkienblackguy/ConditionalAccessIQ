Function ConvertTo-CAIQFlatObject {
    <#
        .SYNOPSIS
        This is a function that flattens objects that have nested objects, hashtables, etc.

        .DESCRIPTION
        This is a function that flattens objects that have nested objects, hashtables, etc.

        .PARAMETER InputObject
        The object to flatten.

        .PARAMETER Prefix
        The prefix to add to the property name.

        .EXAMPLE
        ConvertTo-FlatObject -InputObject $policy

        .INPUTS
        System.Object

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory=$false)]
        [string]$Prefix
    )
    Begin {
        # Initialize the flat object
        $flat_object = New-Object PSObject
    
    } Process {
        # Iterate through each property of the input object
        foreach ($property in $inputObject.PSObject.Properties) {
            # Create the key for the property
            $key = if ($prefix) {
                "$prefix.$($property.Name)" 
            
            } else { 
                $property.Name 
            
            }
            # If the property value is a dictionary or a PSObject, recursively flatten it
            if ($property.Value -is [System.Collections.IDictionary] -or $property.Value -is [PSObject]) {
                $nested_object = ConvertTo-CAIQFlatObject -InputObject $property.Value -Prefix $key

                # Add each nested property to the flat object
                foreach ($nested_property in $nested_object.PSObject.Properties) {
                    $flat_object | Add-Member -NotePropertyName $nested_property.Name -NotePropertyValue $nested_property.Value
                
                }
            } else {
                # Add the property to the flat object
                $flat_object | Add-Member -NotePropertyName $key -NotePropertyValue $property.Value
            
            }
        }
    } End {
        # Return the flat object
        $flat_object
    
    }
}