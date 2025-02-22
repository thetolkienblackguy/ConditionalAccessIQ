Function Set-CAIQHtmlReportActionElements($Action, [Object]$PolicyInfo) {
    <#
        .SYNOPSIS
        Set the display name, by header, and date header based on the action

        .DESCRIPTION
        This function sets the display name, by header, and date header based on the action and policy information.

        .PARAMETER Action
        The action that was performed on the policy.
        
        .PARAMETER PolicyInfo
        The policy information.

        .INPUTS
        System.String
        System.Object

        .OUTPUTS
        System.Object        
    
    #>
    # Set the display name, by header, and date header based on the action
    Switch ($action) {
        "Update" {
            $title = $policyInfo.DisplayName
            $display_name = $policyInfo.DisplayName
            $by_header = "Modified By"
            $date_header = "Modified Date"
            $date_attribute = "ModifiedDateTime"

        } "Add" {
            $title = $policyInfo.DisplayName
            $display_name = "$($policyInfo.DisplayName) **(NEW)**"
            $by_header = "Created By"
            $date_header = "Created Date"
            $date_attribute = "CreatedDateTime"

        } "Delete" {
            $title = $policyInfo.DisplayName
            $display_name = "$($policyInfo.DisplayName) **(DELETED)**"
            $by_header = "Deleted By"
            $date_header = "Deleted Date"
            $date_attribute = "ModifiedDateTime"
        }
    }

    # Create the output object
    $output_obj = [ordered]@{}
    $output_obj["Title"] = $title
    $output_obj["DisplayName"] = $display_name
    $output_obj["ByHeader"] = $by_header
    $output_obj["DateHeader"] = $date_header
    $output_obj["DateAttribute"] = $date_attribute

    # Return the output object
    [pscustomobject]$output_obj
}