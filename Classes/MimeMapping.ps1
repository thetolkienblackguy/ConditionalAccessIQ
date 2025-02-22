<#
    .SYNOPSIS
    A class to map file extensions to MIME types.

    .DESCRIPTION
    The MimeMapping class provides functionality to determine the MIME type of a file based on its extension.
    This class is created as an alternative to System.Web.MimeMapping, which does not work in PowerShell 7.x.

    .EXAMPLE
    $mimeType = [MimeMapping]::GetMimeType("example.txt")
    # Returns: "text/plain"

    .EXAMPLE
    $mimeType = [MimeMapping]::GetMimeType("unknown.xyz")
    # Returns: "application/octet-stream"

    .INPUTS
    
    .OUTPUTS
    System.String

#>
class MimeMapping {
    # Created this class to map file extensions to MIME types as System.Web.MimeMapping does not work in PowerShell 7.x
    static [string] GetMimeType([string]$path) {
        $extension = [System.IO.Path]::GetExtension($path).ToLower()
        if ([string]::IsNullOrEmpty($extension)) {
            return "application/octet-stream"
        
        }

        # Get the MIME type for the file extension
        try {
            $reg_key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($extension)
            
            # If the registry key is found, return the MIME type
            if ($reg_key -and $reg_key.GetValue("Content Type")) {
                return $reg_key.GetValue("Content Type").ToString()
            }
        } catch {
            Write-Verbose "Error getting MIME type for $($extension): $_"
        }
        # If the MIME type is not found, return the default MIME type
        return "application/octet-stream"
    
    }
}