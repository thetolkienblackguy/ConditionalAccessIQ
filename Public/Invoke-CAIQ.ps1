Function Invoke-CAIQ {
    <#
        .SYNOPSIS
        This function is used to compare the current conditional access policies with the last modified policy and create a report of the changes.

        .DESCRIPTION
        This function is used to compare the current conditional access policies with the last modified policy and create a report of the changes.

        .PARAMETER StartDate
        The start date of the audit log.

        .PARAMETER EndDate
        The end date of the audit log.

        .PARAMETER OutputPath
        The path to save the policies to.

        .PARAMETER FileName
        The name of the file to save the report to.

        .PARAMETER Title
        The title of the report.

        .PARAMETER LogPath
        The path to save the log to.

        .PARAMETER AuditLogArchive
        The path to save the audit log archive to.

        .PARAMETER InvokeHtml
        If this switch is specified, the report will be saved to the output path.

        .INPUTS
        System.String
        System.Boolean

        .OUTPUTS
        System.String

        .LINK
        https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/README.md
    #>
    [Alias("Invoke-ConditionalAccessIQ")]
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            $utc_regex = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
            if ($_ -notmatch $utc_regex) {
                throw "StartDate must be in UTC format (yyyy-MM-ddTHH:mm:ssZ)"
            
            }
            return $true
        
        })]
        [string]$StartDate = (Get-Date).AddDays(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"),
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            $utc_regex = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
            if ($_ -notmatch $utc_regex) {
                throw "EndDate must be in UTC format (yyyy-MM-ddTHH:mm:ssZ)"
            }
            if ([DateTime]::ParseExact($_, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture) -lt [DateTime]::ParseExact($StartDate, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)) {
                throw "EndDate cannot be before StartDate"
            
            }
            return $true
        
        })]
        [string]$EndDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ"),
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]$OutputPath = "$($PWD)\ConditionalAccessIQ",
        [Parameter(Mandatory=$false)]
        [string]$FileName = "Conditional_Access_Intelligence.html",
        [Parameter(Mandatory=$false)]
        [string]$Title = "Conditional Access Policy Changes",
        [Parameter(Mandatory=$false)]
        [string]$Logfile = "$($outputPath)\Logs\Invoke-ConditionalAccessIQ_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log",
        [Parameter(Mandatory=$false)]
        [string]$AuditLogArchive = "$($outputPath)\Logs\CAIQ_Audit_Log_Archive.json",
        [Parameter(Mandatory=$false)]
        [bool]$InvokeHtml = $true

    )
    Begin {
        #region Pre Processing
        # Setting default parameter values
        $PSDefaultParameterValues = @{}
        $PSDefaultParameterValues["Invoke-CAIQLogging:Logfile"] = $logFile
        $PSDefaultParameterValues["Invoke-CAIQLogging:WriteOutput"] = $true
        $PSDefaultParameterValues["Sort-Object:Descending"] = $true
        $PSDefaultParameterValues["ConvertFrom-Json:Depth"] = 10
        $PSDefaultParameterValues["ConvertTo-Json:Depth"] = 10
        $PSDefaultParameterValues["Out-File:Append"] = $true

        #endregion

        #region Splatting
        $new_index_params = @{}
        $new_index_params["OutputPath"] = $outputPath
        $new_index_params["Name"] = $fileName
        $new_index_params["Title"] = $title

        #endregion

    } Process {
        #region Get modified and new policies
        $policy_reports = [System.Collections.Generic.List[PSCustomObject]]::new()
        Try {
            Invoke-CAIQLogging -Message "Getting conditional access policies"
            # Get all policies
            $policies = Get-CAIQConditionalAccessPolicy -All -ErrorAction Stop
            Invoke-CAIQLogging -Message "Found $(@($policies).Count) conditional access policies" -ForegroundColor Green
        
        } Catch {
            Invoke-CAIQLogging -Message "Failed to get conditional access policies due to the following error: $_" -ForegroundColor Red
            Exit 1

        }
        Foreach ($policy in $policies) {
            # Get the policy id
            $policy_id = $policy.id

            # Get the policy display name
            $policy_display_name = $policy.DisplayName

            # Build the policy path
            $policy_path = Join-Path -Path $outputPath -ChildPath "Policies\$policy_id"
            
            # Initialize the audit logs list
            $audit_logs = [System.Collections.Generic.List[PSCustomObject]]::new()
            
            # Export-CAIQJson parameters
            $export_json_params = @{}
            $export_json_params["Policy"] = $policy
            $export_json_params["Path"] = $policy_path

            Try {
                If (!(Test-Path -Path $policy_path)) {
                    # Save the policy to the full path
                    Invoke-CAIQLogging -Message "No previous version detected. Saving backup of policy $($policy_display_name) to $($policy_path)"
                    Export-CAIQJson @export_json_params 
                    Invoke-CAIQLogging -Message "Policy $($policy_display_name) has been saved to $($policy_path) successfully" -ForegroundColor Green

                    # Checking if this is a newly created policy
                    Invoke-CAIQLogging -Message "Checking if this is a newly created policy"
                    $add_audit_logs = Get-CAIQDirectoryAuditLog -PolicyId $policy_id -Action "Add"
                    Foreach ($add_audit_log in $add_audit_logs) {
                        $add_audit_log | Add-Member -MemberType NoteProperty -Name "Action" -Value "Add"
                        $audit_logs.Add($add_audit_log)
                    
                    } 
                }   
                # Get the audit logs for the policy
                Invoke-CAIQLogging -Message "Getting the audit logs for the policy $($policy_display_name)"
                $update_audit_logs = Get-CAIQDirectoryAuditLog -PolicyId $policy_id 
                Foreach ($update_audit_log in $update_audit_logs) {
                    # Add the action to the audit log
                    $update_audit_log | Add-Member -MemberType NoteProperty -Name "Action" -Value "Update"

                    # Add the audit log to the audit logs list
                    $audit_logs.Add($update_audit_log)
                
                }

                If (!$audit_logs) {
                    Invoke-CAIQLogging -Message "The policy $($policy_display_name) has no modifications to report" -ForegroundColor Cyan
                
                } Else {
                    Foreach ($audit_log in $audit_logs) {
                        # Invoke-CAIQAuditLogProcessing parameters
                        $process_log_params = @{}
                        $process_log_params["AuditLog"] = $audit_log
                        $process_log_params["Policy"] = $policy
                        $process_log_params["PolicyPath"] = $policy_path

                        # Process the audit log
                        $html_report_obj = Invoke-CAIQAuditLogProcessing @process_log_params

                        # Export the audit log to the audit 
                        Invoke-CAIQLogging -Message "Exporting the audit log to the audit log archive"
                        Try {
                            #$audit_log | Export-Csv -Path $auditLogArchive 
                            $audit_log | ConvertTo-Json | Out-File -FilePath $auditLogArchive -Append

                        } Catch {
                            Invoke-CAIQLogging -Message "Could not export the audit log to the audit log archive due to the following error: $_" -ForegroundColor Red
                        
                        }

                        # Add the HTML report object to the policy reports
                        $policy_reports.Add([PSCustomObject]$html_report_obj)

                    }   
                }
            } Catch {
                Invoke-CAIQLogging -Message "Could not process policy $($policy_display_name) due to the following error: $_" -ForegroundColor Red
            
            }
        }
        
        #endregion
        
        #region Identify and process deleted policies
        # Get the deleted policies
        Invoke-CAIQLogging -Message "Identifying deleted policies"
        $deleted_policies = Get-CAIQDeletedPolicies -Path $outputPath -Policies $policies

        If ($deleted_policies) {
            Invoke-CAIQLogging -Message "Found $(@($deleted_policies).Count) deleted policies" -ForegroundColor Green

            # Build the archived policy path, this is the policy path with policies that have been deleted
            $deleted_policy_path = Join-Path -Path $outputPath -ChildPath "Policies\Deleted"

            Foreach ($deleted_policy in $deleted_policies) {
                Invoke-CAIQLogging -Message "Processing deleted policy $($deleted_policy)"
                # Get the policy id
                $policy_id = $deleted_policy

                # Build the policy path
                $policy_path = Join-Path -Path $outputPath -ChildPath "Policies\$policy_id"

                # Find deletion audit log
                $audit_log = Get-CAIQDirectoryAuditLog -PolicyId $policy_id -Action "Delete"

                If ($audit_log) {
                    # Add the action to the audit log
                    $audit_log | Add-Member -MemberType NoteProperty -Name "Action" -Value "Delete"
                    
                    # Retrieve the policy settings from the audit log
                    $policy = ConvertTo-CAIQConditionalAccessObject -AuditLog $audit_log -ValueType "oldValue"

                    # Invoke-CAIQAuditLogProcessing parameters
                    $process_log_params = @{}
                    $process_log_params["AuditLog"] = $audit_log
                    $process_log_params["Policy"] = $policy
                    $process_log_params["PolicyPath"] = $policy_path

                    # Move-Item parameters
                    $move_item_params = @{}
                    $move_item_params["Path"] = $policy_path
                    $move_item_params["Destination"] = $deleted_policy_path
                    $move_item_params["Force"] = $true

                    # Process the deletion audit log
                    $html_report_obj = Invoke-CAIQAuditLogProcessing @process_log_params

                    # Export the audit log to the audit log archive
                    Invoke-CAIQLogging -Message "Exporting the audit log to the audit log archive"
                    Try {
                        #ConvertTo-CAIQFlatObject -InputObject $audit_log | Export-Csv -Path $auditLogArchive
                        $audit_log | ConvertTo-Json | Set-Content -Path $auditLogArchive

                    } Catch {
                        Invoke-CAIQLogging -Message "Could not export the audit log to the audit log archive due to the following error: $_" -ForegroundColor Red
                    
                    }
                    # Move the deleted policy to the archived folder
                    Invoke-CAIQLogging -Message "Moving the deleted policy's data to $($deleted_policy_path)"
                    Try {
                        Move-Item @move_item_params

                    } Catch {
                        Invoke-CAIQLogging -Message "Could not move the deleted policy's data to $($deleted_policy_path) due to the following error: $_" -ForegroundColor Red
                    
                    }

                    # Add the HTML report object to the policy reports
                    $policy_reports.Add([PSCustomObject]$html_report_obj) 

                } Else {
                    Invoke-CAIQLogging -Message "No deletion audit log found for policy $($deleted_policy)"

                }
            } 
        } Else {
            Invoke-CAIQLogging -Message "No deleted policies found" -ForegroundColor Cyan

        }

        #endregion
    } End {
        #region Post Processing
        If ($policy_reports) {
            Try {
                # Create the html file
                Invoke-CAIQLogging -Message "Creating $($fileName) file"
                $index_html_obj = New-CAIQHtml -PolicyReports $policy_reports @new_index_params
                Invoke-CAIQLogging -Message "$($fileName) created at: $($index_html_obj.Path)" -ForegroundColor Green
                If ($invokeHtml) {
                    Invoke-Item $index_html_obj.Path

                }
            } Catch {
                Invoke-CAIQLogging -Message "Could not create the $($fileName) file due to the following error: $_" -ForegroundColor Red
                Exit 1

            }
        } Else {
            Invoke-CAIQLogging -Message "No policy changes detected." -ForegroundColor Yellow

        }
        #endregion

    }
}