Function New-CAIQBreakGlassExclusionDashboard {
    <#
        .SYNOPSIS
        Generates an HTML report for the Break Glass Assessment.

        .DESCRIPTION
        This function generates an HTML report displaying break glass accounts and the Conditional Access policies from which they are not excluded.
        The report uses existing HTML, CSS, and JavaScript templates.

        .PARAMETER AssessmentResults
        The results of the Break Glass Assessment from Invoke-CAIQBreakGlassAssessment.

        .PARAMETER OutputPath
        The path where the HTML report will be saved.

        .PARAMETER Title
        The title of the HTML report.

        .PARAMETER FileName
        The name of the HTML report file.

        .EXAMPLE
        New-CAIQBreakGlassExclusionDashboard -DataSet $results -OutputPath "C:\Reports"

        .INPUTS
        System.Object

        .OUTPUTS
        System.Object
    
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$DataSet,
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        [Parameter(Mandatory=$false)]
        [string]$Title = "Break Glass Account CA Policy Exclusion Assessment",
        [Parameter(Mandatory=$false)]
        [string]$FileName = "BreakGlass_ConditionalAccessIQ_Exclusion_Assessment.html"
    
    )
    Begin {
        # Initialize the output object
        $output_obj = [ordered]@{}
        
        # Get tenant info
        $tenant_info = Get-CAIQTenantInfo
        
        # Get templates
        Try {
            # Load the templates directly from the template path
            $html_template = $template_manager.GetTemplate("breakglass.html")
            $breakglass_styles = $template_manager.GetTemplate("breakglass_styles.css")
            $breakglass_script = $template_manager.GetTemplate("breakglass_script.js")

        } Catch {
            Write-Error "Error with templates: $_" -ErrorAction Stop
        
        }
        
        # Group assessment results by break glass account
        $grouped_results = $dataSet | Group-Object -Property BreakGlassAccount

        
        # Build tab buttons
        $tab_buttons = [System.Text.StringBuilder]::new()
        foreach ($group in $grouped_results) {
            $account_name = $group.Name
            $account_id = $account_name.Replace("@", "_").Replace(".", "_")
            [void]$tab_buttons.AppendLine("<button class=`"tablinks`" onclick=`"openTab(event, '$account_id')`">$account_name</button>")
        
        }
        
        # Build tab content
        $tab_content = [System.Text.StringBuilder]::new()

        # Initialize the total issues counter
        $total_issues = 0

        $policies_count = @($grouped_results[0].Group).Count
        
        foreach ($group in $grouped_results) {
            # Get the account name and ID
            $account_name = $group.Name

            # Get the account ID
            $account_id = $account_name.Replace("@", "_").Replace(".", "_")

            # Get the policies missing exclusions
            $policies_missing_exclusions = $group.Group | Where-Object {!$_.ExcludedFromPolicy}

            # Get the count of policies missing exclusions
            $missing_exclusions_count = @($policies_missing_exclusions).Count

            # Increment the total issues counter
            $total_issues += $missing_exclusions_count
            
            # Build the tab content
            [void]$tab_content.AppendLine("<div id=`"$account_id`" class=`"tabcontent`">")
            [void]$tab_content.AppendLine("<div class=`"account-info`">")
            [void]$tab_content.AppendLine("<h3>Account: $account_name</h3>")
            [void]$tab_content.AppendLine("<p>Number of policies without proper exclusion: $missing_exclusions_count</p>")
            [void]$tab_content.AppendLine("</div>")
            
            # If there are policies missing exclusions, build the tab content
            if ($policies_missing_exclusions) {
                [void]$tab_content.AppendLine("<h3>Policies Missing Exclusions</h3>")
                [void]$tab_content.AppendLine("<p>The following Conditional Access policies do not exclude this break glass account:</p>")
                [void]$tab_content.AppendLine("<div class=`"policy-cards`">")
                
                # Build the policy cards
                foreach ($policy in $policies_missing_exclusions) {
                    $policy_url = "https://entra.microsoft.com/#view/Microsoft_AAD_ConditionalAccess/PolicyBlade/policyId/$($policy.Id)"
                    [void]$tab_content.AppendLine("<div class=`"policy-card`">")
                    [void]$tab_content.AppendLine("<h3>$($policy.DisplayName)</h3>")
                    [void]$tab_content.AppendLine("<div class=`"policy-id`">ID: $($policy.Id)</div>")
                    
                    # Add status
                    If ($policy.State -eq "enabled") {
                        [void]$tab_content.AppendLine("<div class=`"policy-status`">Enabled</div>")
                    
                    } Else {
                        [void]$tab_content.AppendLine("<div class=`"policy-status`" style=`"background-color: #888;`">$($policy.State)</div>")
                    
                    }

                    # Add link to policy
                    [void]$tab_content.AppendLine("<a href=`"$policy_url`" target=`"_blank`">View Policy in Entra Portal</a>")
                    [void]$tab_content.AppendLine("</div>")
                
                }
                # Close policy cards
                [void]$tab_content.AppendLine("</div>")
            } Else {
                [void]$tab_content.AppendLine("<p>This account is properly excluded from all Conditional Access policies.</p>")
            
            }
            # Close tab content
            [void]$tab_content.AppendLine("</div>")
        
        }
        
        # Determine overall status
        $overall_status = "Good"
        $overall_status_class = "status-good"
        $summary_text = "All break glass accounts are properly excluded from Conditional Access policies."
        
        if ($total_issues) {
            $overall_status = "Critical"
            $overall_status_class = "status-critical"
            $summary_text = "One or more break glass accounts are not excluded from all Conditional Access policies."
        }
        
        $issues_class = if ($total_issues) { 
            "status-critical" 
        } Else { 
            "status-good" 
        
        }
    
    } Process {
        # Create tokens for replacement
        $tokens = @{}
        $tokens["TITLE"] = $title
        $tokens["TENANT_NAME"] = "$($tenant_info.DisplayName) ($($tenant_info.Id))"
        $tokens["STYLES"] = "<style>$breakglass_styles</style>"
        $tokens["SCRIPTS"] = "<script>$breakglass_script</script>"
        $tokens["OVERALL_STATUS_CLASS"] = $overall_status_class
        $tokens["OVERALL_STATUS"] = $overall_status
        $tokens["SUMMARY_TEXT"] = $summary_text
        $tokens["TOTAL_POLICIES"] = $policies_count
        $tokens["TOTAL_ACCOUNTS"] = @($grouped_results).Count
        $tokens["TOTAL_ISSUES"] = $total_issues
        $tokens["ISSUES_CLASS"] = $issues_class
        $tokens["TAB_BUTTONS"] = $tab_buttons.ToString()
        $tokens["TAB_CONTENT"] = $tab_content.ToString()
        $tokens["FOOTER"] = $footer_template
                
        # Replace all tokens in the HTML
        $html_content = $html_template

        # Replace all tokens in the HTML
        foreach ($key in $tokens.Keys) {
            $html_content = $html_content -replace "{{$key}}", $tokens[$key]
        }
        
        # Create the full path for the HTML file
        $report_path = Join-Path -Path $outputPath -ChildPath $FileName
        
        # Write the HTML file
        $html_content | Out-File -FilePath $report_path -Encoding utf8
        
        # Add the HTML file path to the output object
        $output_obj["Path"] = $report_path
        $output_obj["Html"] = $html_content
    
    } End {
        # Return the output object
        [PSCustomObject]$output_obj
    
    }
}