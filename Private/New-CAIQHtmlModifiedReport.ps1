Function New-CAIQHtmlModifiedReport {
    <#
        .SYNOPSIS
        Generates a HTML report of Conditional Access Policy changes.
    
        .DESCRIPTION
        This function generates a HTML report of Conditional Access Policy changes.
        
        .PARAMETER PolicyInfo
        The policy information to include in the HTML report.

        .PARAMETER Differences
        The differences between the old and new policy information.

        .PARAMETER ModifiedBy
        The user who modified the policy.

        .PARAMETER Version
        The version of the policy.

        .PARAMETER Action
        The action that was performed on the policy.

        .PARAMETER ActivityDateTime
        The date and time of the activity.
        
        .EXAMPLE
        New-CAIQHtmlModifiedReport -PolicyInfo $policyInfo -Differences $differences -ModifiedBy $modifiedBy -Version $version -Action $action -ActivityDateTime $activityDateTime

        .INPUTS
        System.Object
        System.String
        System.DateTime

        .OUTPUTS
        System.String
    
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [Object]$PolicyInfo,
        [Parameter(Mandatory=$true)]
        [Object]$Differences,
        [Parameter(Mandatory=$true)]
        [string]$ModifiedBy,
        [Parameter(Mandatory=$true)]
        [string]$Version,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Update", "Delete", "Add")]
        [string]$Action,
        [Parameter(Mandatory=$true)]
        [datetime]$ActivityDateTime
    
    )
    Begin {
        # Get templates
        Try {
            $report_template = $template_manager.GetTemplate("modified_report.html")
            $report_styles = $template_manager.GetTemplate("modified_report_styles.css")

        } Catch {
            Write-Error "Error getting templates: $_" -ErrorAction Stop
        
        }
        
        # Get HTML elements
        $html_elements = Set-CAIQHtmlReportActionElements -Action $action -PolicyInfo $policyInfo
        
        # Get activity date time
        [datetime]$activity_date_time = If (!$policyInfo."$($html_elements.DateAttribute)") {
            $activityDateTime
        
        } Else {
            $policyInfo."$($html_elements.DateAttribute)"
        
        }
        
        # Format changes table
        $total_changes = @($differences).Count
        $changes_table = [System.Text.StringBuilder]::new()
        [void]$changes_table.AppendLine("<table><tr><th>Condition Path</th><th>Condition</th><th>Old Value</th><th>New Value</th></tr>")
        foreach ($difference in $differences) {
            # If the property name is guestOrExternalUserTypes, then get the guest user types
            If ($difference.PropertyName -eq "guestOrExternalUserTypes") {
                $difference.OldValue = Get-CAIQGuestUserTypes -Value $difference.OldValue
                $difference.NewValue = Get-CAIQGuestUserTypes -Value $difference.NewValue
            
            }

            # Skip other authenticationStrength properties if id hasn't changed. 
            # This is a workaround, when conditional access policies have an authenticationStrength applied, any changes to the policy
            # are reported as a change to the authenticationStrengths. However, when an actual authenticationStrength is changed, it includes the
            # id of the authenticationStrength in the property name.
            If ($differences.FullPath -notcontains "grantControls.authenticationStrength.id" -and 
                $difference.FullPath -like "grantControls.authenticationStrength*") {
                $total_changes--
                Continue
            
            }

            # Format the old value
            $old_value_formatted = Format-CAIQValue $difference.OldValue
                
            # Format the new value
            $new_value_formatted = Format-CAIQValue $difference.NewValue
            
            # Build the changes table
            [void]$changes_table.AppendLine("<tr><td>$($difference.FullPath)</td><td>$($difference.PropertyName)</td><td>$old_value_formatted</td><td>$new_value_formatted</td></tr>")
        
        }
        # Close the changes table
        [void]$changes_table.AppendLine("</table>")
    } Process {
        # Replace template tokens
        $html_content = $report_template
        $tokens = @{}
        $tokens["TITLE"] = $html_elements.Title
        $tokens["STYLES"] = "<style>$report_styles</style>"
        $tokens["DISPLAY_NAME"] = $html_elements.DisplayName
        $tokens["POLICY_ID"] = $policyInfo.Id
        $tokens["VERSION"] = $version
        $tokens["DATE_HEADER"] = $html_elements.DateHeader
        $tokens["ACTIVITY_DATE"] = $(ConvertTo-CAIQLocalTime($activity_date_time))
        $tokens["BY_HEADER"] = $html_elements.ByHeader
        $tokens["MODIFIED_BY"] = $modifiedBy
        $tokens["TOTAL_CHANGES"] = $total_changes
        $tokens["CHANGES_TABLE"] = $changes_table.ToString()

        # Replace the tokens
        foreach ($key in $tokens.Keys) {
            $html_content = $html_content -replace "{{$key}}", $tokens[$key]
        
        }
    } End {
        # Return the html content
        $html_content
    
    }
}