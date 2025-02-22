Function Format-CAIQValue($Value) {
    <#
        .SYNOPSIS
        This is a helper function that formats a value for display in the HTML comparison.

        .DESCRIPTION
        This is a helper function that formats a value for display in the HTML comparison.

        .PARAMETER Value
        The value to be formatted.

        .INPUTS
        System.Object

        .OUTPUTS
        System.String
    
    #>
    # Format the value
    If (!$value) {
        "<em>null</em>"
    
    # If the value is an array and not a string, join the elements with commas
    } ElseIf ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
        ($value | ForEach-Object {$_}) -join ", "
    
    # If the value is a string, return it as is
    } Else {
        $value
    
    }
}