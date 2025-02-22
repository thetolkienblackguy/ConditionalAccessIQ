Function ConvertFrom-CAIQObjectId {
    [CmdletBinding()]
    [OutputType([system.object])]
    Param (
        [Parameter(Mandatory=$true)]
        [object]$Differences
    
    )
    <#
        .SYNOPSIS
        Helper function to convert the object IDs to display names

        .DESCRIPTION
        This function converts the object IDs to display names for the differences object

        .PARAMETER Differences
        The differences object to convert

        .INPUTS
        System.Object

        .OUTPUTS
        System.Object
    
    #>
    # Regex to determine if the property name is an object that requires conversion
    $property_regex = "(?i)(?<!guestsorexternal)(include|exclude)(users|groups|applications|roles)(?<!guestsorexternaluser)"

    # Get the convertable objects
    $convertable_objs = $differences | Where-Object {
        $_.PropertyName -match $property_regex 
    
    }

    # Loop through each object
    Foreach ($obj in $convertable_objs) {
        # Get the graph endpoint to use depending on the property name
        $endpoint = Get-CAIQDirectoryObjectEndpoint($obj.PropertyName)

        # If the endpoint is not found, continue
        If (!$endpoint) {
            Continue 
        
            } Else { 
            # Create new lists to store the display names
            $new_value = [system.collections.generic.list[string]]::new()
            $old_value = [system.collections.generic.list[string]]::new()

            # Get-CAIQDirectoryObjectDisplayName parameters
            $get_name_params = @{}
            $get_name_params['Endpoint'] = $endpoint

            # Loop through each ID in the new value
            Foreach ($id in $obj.NewValue) {
                Try {
                    $display_name = Get-CAIQDirectoryObjectDisplayName -DirectoryObjectId $id @get_name_params
                    $new_value.Add($display_name)

                } Catch {
                    $new_value.Add("[DELETED] $id")
                    Write-Warning "Could not convert $id to a display name"
                
                }
            }

            # Loop through each ID in the old value
            Foreach ($id in $obj.OldValue) {
                Try {
                    $display_name = Get-CAIQDirectoryObjectDisplayName -DirectoryObjectId $id @get_name_params
                    $old_value.Add($display_name)

                } Catch {
                    $old_value.Add("[DELETED] $id")
                    Write-Warning "Could not convert $id to a display name"
                
                }
            }
        }
        # Update the new and old values with the display names
        $differences | Where-Object {
            $_.PropertyName -eq $obj.PropertyName
        } | ForEach-Object {
            $_.NewValue = $new_value -join ", "
            $_.OldValue = $old_value -join ", "
        
        }
    }
    # Return the updated differences object
    $differences 
}