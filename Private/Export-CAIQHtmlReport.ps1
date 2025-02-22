Function Export-CAIQHtmlReport {
    <#
        .SYNOPSIS
        This is a function that exports an HTML report.

        .DESCRIPTION
        This is a function that exports an HTML report.

        .PARAMETER HtmlReport
        The HTML report string.

        .PARAMETER Path
        The path to export the HTML report to.

        .PARAMETER Version
        The version of the policy.

        .PARAMETER PolicyId
        The Id of the policy.

        .EXAMPLE
        Export-CAIQHtmlReport -HtmlReport $html_report -Path $path -Version $version -PolicyId $policy_id
    
    #>
    Param (
        [Parameter(Mandatory=$true)]
        [string]$HtmlReport,
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Version,
        [Parameter(Mandatory=$true)]
        [object]$PolicyId
    
    )
    # Create the full path
    $file_name = "$($policyId)_Version_$($version).html"
    $full_path = Join-Path -Path $path -ChildPath $file_name
  
    # Write the HTML report to the file
    $html_report | Out-File -FilePath $full_path

    # Return the full path
    $full_path
}