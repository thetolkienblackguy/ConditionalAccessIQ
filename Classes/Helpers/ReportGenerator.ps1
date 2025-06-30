class ReportGenerator {

    # Private field to hold the TemplateManager instance.
    hidden [TemplateManager]$TemplateManager

    # Constructor for the class.
    ReportGenerator([string]$moduleBasePath) {
        # Define the path to the templates directory.
        $template_path = Join-Path -Path $moduleBasePath -ChildPath "Templates"

        # Initialize the TemplateManager to handle loading of HTML/CSS templates.
        $this.TemplateManager = [TemplateManager]::new($template_path)
    
    }

    # Method to generate the HTML for the JSON download button.
    # This method is hidden as it is an internal implementation detail.
    hidden [string]BuildCADownloadButton([string]$jsonBackup, [string]$policyName) {
        # Create a string builder to construct the HTML.
        $download_button = [System.Text.StringBuilder]::new()

        # If a JSON backup is provided, create a download link.
        if ($jsonBackup) {
            # Convert the backup to a base64 string for the download link.
            $json_bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBackup)
            $json_base64 = [Convert]::ToBase64String($json_bytes)
            [void]$download_button.AppendLine("<a href=`"data:application/json;base64,$json_base64`" download=`"$($policyName)_Backup.json`" class=`"download-btn`">Download Previous Version's JSON</a>")
        } else {
            [void]$download_button.AppendLine("<span>No previous version available for download</span>")
        
        }

        # Return the final HTML string for the button.
        return $download_button.ToString()
    
    }

    # Method to replace placeholder tokens in an HTML template.
    # This method is hidden as it is an internal implementation detail.
    hidden [string]ReplaceTokensInTemplate([string]$htmlContent, [hashtable]$tokens) {
        # Loop through the tokens and replace them in the HTML content.
        foreach ($token in $tokens.Keys) {
            $htmlContent = $htmlContent -replace [regex]::Escape("{{$token}}"), $tokens[$token]
        
        }

        # Return the modified HTML content.
        return $htmlContent
    }

    # Method to determine the correct headers and display text based on the action.
    hidden [pscustomobject]GetCAReportActionElements([string]$action, [object]$policyInfo) {
        # Create an ordered hashtable to store the element details.
        $output_obj = [ordered]@{}
        $output_obj['Title'] = $policyInfo.DisplayName
        $output_obj['DisplayName'] = $policyInfo.DisplayName
        $output_obj['ByHeader'] = "Modified By"
        $output_obj['DateHeader'] = "Modified Date"
        $output_obj['DateAttribute'] = "modifiedDateTime"

        # Use a switch to set the correct text based on the action.
        switch ($action) {
            "Add" {
                $output_obj['DisplayName'] = "$($policyInfo.DisplayName) **(NEW)**"
                $output_obj['ByHeader'] = "Created By"
                $output_obj['DateHeader'] = "Created Date"
                $output_obj['DateAttribute'] = "createdDateTime"
            
            } "Delete" {
                $output_obj['DisplayName'] = "$($policyInfo.DisplayName) **(DELETED)**"
                $output_obj['ByHeader'] = "Deleted By"
                $output_obj['DateHeader'] = "Deleted Date"
            }
        }
        # Return the details as a PSCustomObject.
        return [PSCustomObject]$output_obj
    }



    # Method to format a value for clean display in the HTML report.
    hidden [string]FormatValueForDisplay([object]$value) {
        # If the value is null, return an italicized 'null'.
        if (!$value) {
            return "<em>null</em>"
        
        # If the value is an array, join its elements into a comma-separated string.
        } elseif ($value -is [array]) {
            return ($value | ForEach-Object { 
                $_ 
            }) -join ", "
        
        # Otherwise, return the value as a simple string.
        } else {
            return "$value"
        
        }
    }

    # Method to create a table of changes for the CA Change Detail Report.
    [string]CreateCAChangeTable([object]$differences) {
        # Create a string builder to construct the HTML.
        $changes_table = [System.Text.StringBuilder]::new()

        # Build the HTML table of detailed changes.
        [void]$changes_table.AppendLine("<table><tr><th>Condition Path</th><th>Condition</th><th>Old Value</th><th>New Value</th></tr>")
        foreach ($difference in $differences) {
            # Format the old and new values for display.
            $old_value_formatted = $this.FormatValueForDisplay($difference.OldValue)
            $new_value_formatted = $this.FormatValueForDisplay($difference.NewValue)

            # Build the HTML table row.
            [void]$changes_table.AppendLine("<tr><td>$($difference.FullPath)</td><td>$($difference.PropertyName)</td><td>$old_value_formatted</td><td>$new_value_formatted</td></tr>")
        
        }

        # Close the table.
        [void]$changes_table.AppendLine("</table>")

        # Return the final HTML string for the table.
        return $changes_table.ToString()
    
    }

    # Public method to generate the detailed HTML report snippet for a single policy change.
    [string]CreateCAChangeDetailReport(
        [object]$policyInfo, [object]$differences, [string]$modifiedBy, 
        [string]$version, [string]$action, [datetime]$activityDateTime, 
        [string]$jsonBackup)  {
        # Load required templates for the report.
        $report_template = $this.TemplateManager.GetTemplate("modified_report.html")
        $report_styles = $this.TemplateManager.GetTemplate("modified_report_styles.css")
        $html_content = $report_template

        # Get the action-specific display elements using the helper method.
        $html_elements = $this.GetCAReportActionElements($action, $policyInfo)
        $date_attribute = $html_elements.DateAttribute
        $activity_date = if ($policyInfo.$date_attribute) {
            $policyInfo.$date_attribute
        
        } else {
            $activityDateTime
        
        }

        # Build the HTML table of detailed changes.
        $changes_table = $this.CreateCAChangeTable($differences)

        # Create the tokens hashtable for dynamic replacement.
        $tokens = [ordered]@{}
        $tokens['TITLE'] = $html_elements.Title
        $tokens['STYLES'] = "<style>$report_styles</style>"
        $tokens['DOWNLOAD_BUTTON'] = $this.BuildDownloadButton($jsonBackup, $policyInfo.DisplayName)
        $tokens['DISPLAY_NAME'] = $html_elements.DisplayName
        $tokens['POLICY_ID'] = $policyInfo.Id
        $tokens['VERSION'] = $version
        $tokens['DATE_HEADER'] = $html_elements.DateHeader
        $tokens['ACTIVITY_DATE'] = ($activity_date.ToLocalTime().ToString("MM/dd/yyyy HH:mm:ss"))
        $tokens['BY_HEADER'] = $html_elements.ByHeader
        $tokens['MODIFIED_BY'] = $modifiedBy
        $tokens['TOTAL_CHANGES'] = $differences.Count
        $tokens['CHANGES_TABLE'] = $changes_table.ToString()

        # Replace all tokens using the helper method.
        $html_content = $this.ReplaceTokensInTemplate($html_content, $tokens)

        # Return the final HTML string for this single report.
        return $html_content
    }

    # Public method to generate the HTML dashboard for the Break Glass Assessment.
    [string]CreateBreakGlassReport([object[]]$dataSet, [string]$title, [string]$tenantName) {
        # Load required templates for the dashboard.
        $dashboard_template = $this.TemplateManager.GetTemplate("breakglass.html")
        $dashboard_styles = $this.TemplateManager.GetTemplate("breakglass_styles.css")
        $dashboard_script = $this.TemplateManager.GetTemplate("breakglass_script.js")
        $footer_template = $this.TemplateManager.GetTemplate("footer.html")
        $html_content = $dashboard_template

        # Group the assessment results by break glass account UPN.
        $grouped_results = $dataSet | Group-Object -Property BreakGlassAccount

        # Build the HTML for the tab buttons.
        $tab_buttons = [System.Text.StringBuilder]::new()
        foreach ($group in $grouped_results) {
            $account_name = $group.Name
            $account_id = $account_name.Replace("@", "_").Replace(".", "_")
            [void]$tab_buttons.AppendLine("<button class=`"tablinks`" onclick=`"openTab(event, '$account_id')`">$account_name</button>")
        }

        # Build the HTML for the content of each tab.
        $tab_content = [System.Text.StringBuilder]::new()
        $total_issues = 0
        $policies_count = @($grouped_results[0].Group).Count

        foreach ($group in $grouped_results) {
            $account_name = $group.Name
            $account_id = $account_name.Replace("@", "_").Replace(".", "_")
            $policies_missing_exclusions = $group.Group | Where-Object { 
                !$_.IsExcluded 
            
            }
            $missing_exclusions_count = @($policies_missing_exclusions).Count
            $total_issues += $missing_exclusions_count

            [void]$tab_content.AppendLine("<div id=`"$account_id`" class=`"tabcontent`">")
            [void]$tab_content.AppendLine("<div class=`"account-info`"><h3>Account: $account_name</h3><p>Number of policies without proper exclusion: $missing_exclusions_count</p></div>")

            if ($policies_missing_exclusions) {
                [void]$tab_content.AppendLine("<h3>Policies Missing Exclusions</h3><div class=`"policy-cards`">")
                foreach ($policy in $policies_missing_exclusions) {
                    $policy_url = "https://entra.microsoft.com/#view/Microsoft_AAD_ConditionalAccess/PolicyBlade/policyId/$($policy.PolicyId)"
                    $status_style = if ($policy.PolicyState -ne "enabled") { 
                        "style=`"background-color: #888;`"" 
                    
                    } else { 
                        $null 
                    
                    }
                    [void]$tab_content.AppendLine("<div class=`"policy-card`"><h3>$($policy.PolicyDisplayName)</h3><div class=`"policy-id`">ID: $($policy.PolicyId)</div><div class=`"policy-status`" $status_style>$($policy.PolicyState)</div><a href=`"$policy_url`" target=`"_blank`">View Policy in Entra Portal</a></div>")
                
                }
                [void]$tab_content.AppendLine("</div>")
            
            } else {
                [void]$tab_content.AppendLine("<p>This account is properly excluded from all Conditional Access policies.</p>")
            
            }
            [void]$tab_content.AppendLine("</div>")
        
        }

        # Determine the overall status for the summary card.
        $overall_status = if ($total_issues -gt 0) { 
            "Critical" 
        
        } else { 
            "Good" 
        
        }
        $overall_status_class = "status-$($overall_status.ToLower())"
        $summary_text = if ($total_issues -gt 0) { 
            "One or more break glass accounts are not excluded from all Conditional Access policies." 
        
        } else { 
            "All break glass accounts are properly excluded from Conditional Access policies." 
        
        }
        $issues_class = if ($total_issues) { 
            "status-critical" 
        
        } else { 
            "status-good" 
        
        }

        # Create the tokens hashtable for dynamic replacement.
        $tokens = [ordered]@{}
        $tokens['TITLE'] = $title
        $tokens['TENANT_NAME'] = $tenantName
        $tokens['STYLES'] = "<style>$dashboard_styles</style>"
        $tokens['SCRIPTS'] = "<script>$dashboard_script</script>"
        $tokens['OVERALL_STATUS_CLASS'] = $overall_status_class
        $tokens['OVERALL_STATUS'] = $overall_status
        $tokens['SUMMARY_TEXT'] = $summary_text
        $tokens['TOTAL_POLICIES'] = $policies_count
        $tokens['TOTAL_ACCOUNTS'] = @($grouped_results).Count
        $tokens['TOTAL_ISSUES'] = $total_issues
        $tokens['ISSUES_CLASS'] = $issues_class
        $tokens['TAB_BUTTONS'] = $tab_buttons.ToString()
        $tokens['TAB_CONTENT'] = $tab_content.ToString()
        $tokens['FOOTER'] = $footer_template

        # Replace all tokens using the helper method.
        $html_content = $this.ReplaceTokensInTemplate($html_content, $tokens)

        # Return the final HTML string for the dashboard.
        return $html_content
    
    }
}