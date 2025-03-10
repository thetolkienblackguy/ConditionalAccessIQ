function Get-CAIQGraphEndpoint {
    <#
        .SYNOPSIS
        Get the Microsoft Graph endpoint

        .DESCRIPTION
        Get the Microsoft Graph endpoint

        .INPUTS
        None

        .OUTPUTS
        System.String
        
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param()
    
    $context = Get-MgContext -ErrorAction Stop

    If($context) {
        (Get-MgEnvironment -Name $context.Environment -ErrorAction Stop).GraphEndpoint
    
    } Else {
        throw "Authentication needed. Please call Connect-MgGraph."
    
    }
}