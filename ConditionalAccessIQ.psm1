# Set default parameters
$PSDefaultParameterValues["Get-ChildItem:File"] = $true
$PSDefaultParameterValues["Join-Path:Path"] = $PSScriptRoot

$script:template_path = Join-Path -ChildPath "Templates"

# Import all classes, private functions, and public functions
Foreach ($import in @("Classes", "Private", "Public")) {
    # Get the path to the import folder
    $path = Join-Path -ChildPath "$($import)\*.ps1"

    # Get all the files in the import folder
    $files = Get-ChildItem -Path $path -File

    # Dot source all the files
    Foreach ($file in $files) {
        . $file.FullName

        # Export public functions
        If ($import -eq "Public") {
            Export-ModuleMember -Function $file.BaseName
        
        }
    }
}

# Initialize the template manager class
$script:template_manager = [TemplateManager]::new($script:template_path)