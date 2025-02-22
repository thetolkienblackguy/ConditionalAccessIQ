Function Invoke-CAIQAuditLogProcessing {
    <#
        .SYNOPSIS
        This function processes conditional access policies data from Entra Id audit logs and creates an object that can be used to create an HTML report

        .DESCRIPTION
        This function processes the audit logs and creates the HTML report.

        .PARAMETER AuditLog
        The audit log object.

        .PARAMETER Policy
        The policy object.

        .PARAMETER PolicyPath
        The path to the policy.

        .INPUTS
        System.Object
        System.String

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true)]
        [object]$AuditLog,
        [Parameter(Mandatory=$true)]
        [object]$Policy,
        [Parameter(Mandatory=$true)]
        [string]$PolicyPath    
        
    )
    Begin {
        $ErrorActionPreference = "Stop"
        # Export-CAIQJson parameters
        $export_json_params = @{}
        $export_json_params["Policy"] = $policy
        $export_json_params["Path"] = $policyPath

        # Get the policy id
        $policy_id = $policy.id

        # Get the policy display name
        $policy_display_name = $policy.displayName

    } Process {
        # Get the file version using the audit log activity date time
        $file_version = $auditLog.ActivityDateTime.ToString("MM_dd_yyyy_hh_mm_ss")

        # Get the immutable version using the audit log id
        $immutable_version = $auditLog.id

        # Get the json path
        $json_path = Join-Path -Path $policyPath -ChildPath "$($policy_id)_Version_$($file_version).json"

        # Check if the json path exists
        If (Test-Path -Path $json_path) {
            Invoke-CAIQLogging -Message "There is a backup with audit log id $($immutable_version) and file version $($file_version) of the policy $($policy_display_name) saved $($json_path)" -ForegroundColor Cyan
            Continue
        
        }
        Try {
            # Get the reference policy which is the last modified policy, new policies will return null
            $reference_policy = ConvertTo-CAIQConditionalAccessObject -AuditLog $auditLog -ValueType "oldValue"

        } Catch {
            Invoke-CAIQLogging -Message "Unable to convert the reference policy json to an object due to the following error: $_" -ForegroundColor Red
        
        }
        Try {
            # Get the difference policy which is the current policy, deleted policies will return null
            $difference_policy = ConvertTo-CAIQConditionalAccessObject -AuditLog $auditLog -ValueType "newValue"

        } Catch {
            Invoke-CAIQLogging -Message "Unable to convert the difference policy json to an object due to the following error: $_" -ForegroundColor Red
        
        }

        # Compare the policies recursively
        Invoke-CAIQLogging -Message "Identifying changes between the current policy and the last modified policy" -ForegroundColor White
        Try {   
            $differences = Compare-CAIQObjects -ReferenceObject $reference_policy -DifferenceObject $difference_policy
            Invoke-CAIQLogging -Message "Differences: $(($differences | ConvertTo-Json))" -ForegroundColor Cyan

        } Catch {
            Invoke-CAIQLogging -Message "Comparison of the policies failed due to the following error: $_" -ForegroundColor Red
        
        }

        # Convert the differences object to display names
        #Try {
        $differences = ConvertFrom-CAIQObjectId -Differences $differences

        #} Catch {
        #    Invoke-CAIQLogging -Message "Error converting object ids to display names: $_" -ForegroundColor Red
        
        #}
    
        # Save the current policy to the full path
        Invoke-CAIQLogging -Message "Saving the current version of the policy $($policy_display_name) to the full path"
        Try {
            Export-CAIQJson @export_json_params -Version $file_version

        } Catch {
            Invoke-CAIQLogging -Message "Unable to backup  policy to json due to the following error: $_" -ForegroundColor Red
        
        }

        # Get the modified by
        Invoke-CAIQLogging -Message "Getting the modified by for the policy $($policy_display_name)"
        $modified_by = Get-CAIQModifiedBy($auditLog)

        # New-CAIQHtmlReport parameters
        $new_html_report = @{}
        If ($auditLog.Action -eq "Delete") {
            $new_html_report["PolicyInfo"] = $reference_policy

        } Else {
            $new_html_report["PolicyInfo"] = $difference_policy

        }
        $new_html_report["Differences"] = $differences
        $new_html_report["ModifiedBy"] = $modified_by
        $new_html_report["Version"] = $immutable_version
        $new_html_report["Action"] = $auditLog.Action
        $new_html_report["ActivityDateTime"] = $auditLog.ActivityDateTime

        # Create the HTML report
        Invoke-CAIQLogging -Message "Creating the HTML report for the policy $($policy_display_name)"
        Try {
            $html_report = New-CAIQHtmlModifiedReport @new_html_report

        } Catch {
            Invoke-CAIQLogging -Message "Unable to create the HTML report due to the following error: $_" -ForegroundColor Red
        
        }

        # Export-CAIQHtmlReport parameters
        $export_html_params = @{}
        $export_html_params["HtmlReport"] = $html_report
        $export_html_params["Path"] = $policyPath
        $export_html_params["Version"] = $file_version
        $export_html_params["PolicyId"] = $policy_id

        # Export the HTML report
        Invoke-CAIQLogging -Message "Exporting the HTML report for the policy $($policy_display_name) to $($policyPath)"
        Try {   
            $export_path = Export-CAIQHtmlReport @export_html_params
            Invoke-CAIQLogging -Message "The HTML report has been saved to $($export_path) successfully" -ForegroundColor Green

        } Catch {
            Invoke-CAIQLogging -Message "Unable to export the HTML report due to the following error: $_" -ForegroundColor Red
        
        }

        # Create the HTML report object
        $html_report_obj = [ordered]@{}
        $html_report_obj["Path"] = $export_path
        $html_report_obj["Html"] = $html_report
        $html_report_obj["Policy"] = $policy_display_name
        $html_report_obj["Backup"] = $reference_policy | ConvertTo-Json
    
    } End {
        $html_report_obj
    
    }
}