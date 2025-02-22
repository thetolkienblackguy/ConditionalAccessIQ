Function ConvertTo-CAIQLocalTime($DateTime) {
    <#
        .SYNOPSIS
        Helper function to convert the datetime to local time

        .DESCRIPTION
        Helper function to convert the datetime to local time
a
        .PARAMETER DateTime
        The datetime to convert

        .INPUTS
        System.DateTime

        .OUTPUTS
        System.String
    
        #>
    $local_time = $dateTime.ToLocalTime().ToString("MM/dd/yyyy HH:mm:ss")
    $local_time

}
