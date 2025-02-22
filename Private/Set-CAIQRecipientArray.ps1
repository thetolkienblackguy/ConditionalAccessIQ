Function Set-CAIQRecipientArray {
    <#
        .SYNOPSIS
        This is a helper function to create a recipient array for the Send-CAIQMailMessage function.

        .DESCRIPTION
        This is a helper function to create a recipient array for the Send-CAIQMailMessage function.

        .PARAMETER Recipients
        The array of recipients to be added to the mail message.

        .INPUTS
        System.Array

        .OUTPUTS
        System.Object
        
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSObject]])]
    param (   
        [Parameter(Mandatory=$true)]
        [string[]]$Recipients

    )
    Begin {
        # Create the recipient array
        $recipient_array = [system.collections.generic.list[psobject]]::new()
        
    } Process {
        # Loop through each recipient and add it to the recipient array
        Foreach ($recipient in $recipients) {
            # Create the address table          
            $address = @{}
            $address["address"] = $recipient

            # Create the recipient table
            $recipient_table = @{}
            $recipient_table["emailAddress"] = $address

            # Add the recipient table to the recipient array
            $recipient_array.Add($recipient_table)

        }
    } End {
        # Return the recipient array
        $recipient_array

    }  
}