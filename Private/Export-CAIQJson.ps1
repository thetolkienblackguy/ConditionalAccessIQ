Function Export-CAIQJson {
    <#
        .SYNOPSIS
        This function exports a conditional access policy to a JSON file.

        .DESCRIPTION
        This function exports a conditional access policy to a JSON file.

        .PARAMETER Policy
        The conditional access policy to be exported.   

        .PARAMETER Path
        The path to the directory where the JSON file will be created.

        .PARAMETER Version
        The version of the policy to be exported.

        .PARAMETER PassThru
        If this switch is specified, the function will return the path to the JSON file.

        .EXAMPLE
        Export-CAIQJson -Policy $policy -Path "C:\Temp" -Version "1" -PassThru

        .INPUTS
        System.Object
        System.String
        System.Switch

        .OUTPUTS
        System.String

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Policy,
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [string]$Version = "Initial",
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    
    )
    Begin {
        # Ensure the directory exists
        if (!(Test-Path -Path $path)) {
            New-Item -Path $path -ItemType Directory | Out-Null
        
        }
        
        # Create the full path for the file
        $file_name = "$($policy.Id)_Version_$version.json"
        $full_path = Join-Path -Path $path -ChildPath $file_name
    
    } Process {
        Try {
            # Convert the policy to JSON and save it
            $policy | ConvertTo-Json -Depth 10 | Out-File -FilePath $full_path -Force
            Write-Verbose "Policy exported to: $full_path"
        
        } Catch {
            Write-Error "Failed to export policy to $full_path. Error: $_"
        
        }

    } End {
        If ($passThru) {
            $full_path
        
        }
    }
}