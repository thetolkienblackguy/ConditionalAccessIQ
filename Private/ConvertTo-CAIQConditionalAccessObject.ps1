Function ConvertTo-CAIQConditionalAccessObject {
    <#
        .SYNOPSIS
        Convert the oldValue or newValue from the audit log to a policy object

        .DESCRIPTION
        This function converts the oldValue or newValue from the audit log to a policy object.

        .PARAMETER AuditLog
        The audit log object.

        .PARAMETER ValueType
        The type of value to convert.  Either "oldValue" or "newValue".

        .INPUTS
        System.String
        System.Object

        .OUTPUTS
        System.Object

    #>
    Param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AuditLog,
        [Parameter(Mandatory=$true)]
        [ValidateSet("oldValue","newValue")]
        [string]$ValueType

    )

    $value = $audit_log.targetResources.modifiedProperties."$($valueType)"
    If ($value) {
        $policy = $value | ConvertFrom-Json
    
    } Else {
        $policy = $null
    }
    $policy

}