Function New-CAIQHtml {
    <#
        .SYNOPSIS
        Generates a HTML report of Conditional Access Policy changes.
        
        .DESCRIPTION
        This function generates a HTML report of Conditional Access Policy changes.
        
        .PARAMETER PolicyReports
        A list of policy reports to include in the HTML report.
        
        .PARAMETER OutputPath
        The path to save the HTML report.
        
        .PARAMETER Title
        The title of the HTML report.   
        
        .PARAMETER Name
        The name of the HTML report.
        
        .EXAMPLE
        New-CAIQHtml -PolicyReports $policyReports -OutputPath $outputPath -Title $title -Name $name 
        
        .INPUTS
        System.Collections.Generic.List[PSCustomObject]
        System.String

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true)]
        [System.Collections.Generic.List[PSCustomObject]]$PolicyReports,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        [Parameter(Mandatory=$false)]
        [string]$Title = "Conditional Access Policy Changes",
        [Parameter(Mandatory=$false)]
        [string]$Name = "Conditional_Access_Intelligence.html"
    
    )    
    Begin {
        # Initialize the output object
        $output_obj = [ordered]@{}
        
        # Get templates
        Try {
            $main_template = $template_manager.GetTemplate("main.html")
            $main_styles = $template_manager.GetTemplate("main_styles.css")
            $footer_template = $template_manager.GetTemplate("footer.html")

        } Catch {
            Write-Error "Error getting templates: $_" -ErrorAction Stop
        
        }
        
        # Build policy list
        $policy_list = [System.Text.StringBuilder]::new()
        foreach ($report in $policyReports) {
            [void]$policy_list.AppendLine("<li><a href=`"#$($report.Policy)`">$($report.Policy)</a></li>")
        }
        
        # Build detailed reports
        $detailed_reports = [System.Text.StringBuilder]::new()
        foreach ($report in $policyReports) {
            # Build the download button
            $download_button = [System.Text.StringBuilder]::new()
            if ($report.Backup) {
                # Convert the backup to a base64 string
                $json_bytes = [System.Text.Encoding]::UTF8.GetBytes($report.Backup)
                $json_base64 = [Convert]::ToBase64String($json_bytes)
                
                # Build the download button
                [void]$download_button.AppendLine("<a href=`"data:application/json;base64,$json_base64`" download=`"$($report.Policy)_Backup.json`" class=`"download-btn`">Download Previous Version's JSON</a>")
            
            } Else {
                # Build the no backup available message
                [void]$download_button.AppendLine("<span>No backup available</span>")
            
            }
            # Build the detailed report
            [void]$detailed_reports.AppendLine("<div id=`"$($report.Policy)`" class=`"policy-report`">")
            [void]$detailed_reports.AppendLine("<h3>$($report.Policy)</h3>")
            [void]$detailed_reports.AppendLine("$($download_button.ToString())")
            [void]$detailed_reports.AppendLine("$($report.Html)")
            [void]$detailed_reports.AppendLine("</div>")
        
        }
    } Process {
        # Replace template tokens
        $html = $main_template

        # Replace the tokens
        $tokens = @{}
        $tokens["TITLE"] = $title
        $tokens["STYLES"] = "<style>$main_styles</style>"
        $tokens["RESTORE_NOTICE"] = 'To restore a Conditional Access Policy using the downloaded JSON, please refer to this article: <a href="https://techcommunity.microsoft.com/t5/microsoft-entra/conditional-access-upload-policy-file-preview/m-p/3835296" target="_blank">Conditional Access: Upload Policy File (Preview)</a>'
        $tokens["POLICY_LIST"] = $policy_list.ToString()
        $tokens["DETAILED_REPORTS"] = $detailed_reports.ToString()
        $tokens["FOOTER"] = $footer_template
        
        # Replace the tokens in the html
        foreach ($token in $tokens.Keys) {
            $html = $html -replace "{{$token}}", $tokens[$token]
        
        }
        
        # Create the full path for the html file
        $index_path = Join-Path -Path $outputPath -ChildPath $name

        # Write the html file
        $html | Out-File -FilePath $index_path -Encoding utf8

        # Add the html file path to the output object
        $output_obj["Path"] = $index_path
        $output_obj["Html"] = $html
    } End {
        # Return the output object
        [PSCustomObject]$output_obj
    
    }
}