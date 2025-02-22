Function Set-CAIQAttachmentArray {
    <#
        .SYNOPSIS
        This is a helper function to create an attachment array for the Send-CAIQMailMessage function.

        .DESCRIPTION
        This is a helper function to create an attachment array for the Send-CAIQMailMessage function.

        .PARAMETER Attachment
        The array of attachments to be added to the mail message.

        .INPUTS
        System.Array

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (   
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [array]$Attachments

    )
    Begin {
        # Create the attachment array
        $attachment_array = [system.collections.generic.list[psobject]]::new()

    } Process {
        # Loop through each attachment and add it to the attachment array
        Foreach ($attachment in $attachments) {
            # Get the file info
            $attachment_file_info = Get-Item $attachment
            
            # Create the attachment table
            $attachment_table = @{}
            $attachment_table["@odata.type"] = "#microsoft.graph.fileAttachment"
            $attachment_table["name"] = $attachment | Split-Path -Leaf
            $attachment_table["contentType"] = [MimeMapping]::GetMimeType($attachment_file_info.FullName)
            $attachment_table["contentBytes"] = [Convert]::ToBase64String([IO.File]::ReadAllBytes(($attachment_file_info).FullName))
            
            # Add the attachment table to the attachment array
            $attachment_array.Add($attachment_table)

        }
    } End {
        $attachment_array

    }  
}
