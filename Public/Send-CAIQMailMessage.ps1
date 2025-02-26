Function Send-CAIQMailMessage {
    <#
        .DESCRIPTION
        This function sends an email message using the Microsoft Graph API.

        .SYNOPSIS
        This function sends an email message using the Microsoft Graph API.

        .PARAMETER To
        Specifies the recipient(s) of the email message.

        .PARAMETER Subject
        Specifies the subject of the email message.

        .PARAMETER Body
        Specifies the body of the email message.

        .PARAMETER From
        Specifies the sender of the email message.

        .PARAMETER Cc
        Specifies the carbon copy recipient(s) of the email message.

        .PARAMETER Bcc
        Specifies the blind carbon copy recipient(s) of the email message.

        .PARAMETER Attachments
        Specifies the attachment(s) of the email message.

        .PARAMETER Importance
        Specifies the importance of the email message.

        .PARAMETER SaveToSentItems
        Specifies whether to save the email message to the sent items folder.

        .EXAMPLE
        Send-CAIQMailMessage -To "john.doe@contoso.com" -From "jane.doe@contoso.com" -Subject "Test" -Body "This is a test"

        .EXAMPLE
        Send-CAIQMailMessage -To "john.doe@contoso.com" -From "jane.doe@contoso.com" -Subject "Test" -Body "This is a test" -Attachments "C:\Temp\test.txt"

        .INPUTS
        System.String
        System.IO.FileInfo
        System.Boolean

        .LINK
        https://docs.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http
    
    #>
    [CmdletBinding()]
    [OutputType()]
    param (      
        [Parameter(Mandatory=$true)]
        [Alias("Recipient")]
        [string[]]$To,
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        [Parameter(Mandatory=$true)]
        [Alias("EmailBody")]
        [string]$Body,
        [Parameter(Mandatory=$true)]
        [Alias("Sender")]
        [string]$From,
        [Parameter(Mandatory=$false)]
        [string[]]$Cc,
        [Parameter(Mandatory=$false)]
        [string[]]$Bcc,
        [Parameter(Mandatory=$false)]
        [system.io.fileinfo[]]$Attachments,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Low", "Normal", "High")]
        [string]$Importance = "Normal",
        [Parameter(Mandatory=$false)]
        [bool]$SaveToSentItems = $true

    )
    Begin {
        # Get the Microsoft Graph endpoint, if not already set
        If (!$script:graph_endpoint) {
            $script:graph_endpoint = Get-CAIQGraphEndpoint
        
        }

        # Creating parent message hash table
        $mail_message = @{}
        $mail_message["message"] = ""
        $mail_message["saveToSentItems"] = $saveToSentItems
           
        # Creating message hash table
        $message = @{}
        $message["subject"] =  $subject
        $message["body"] = @{}
        $message["body"]["contentType"] = "HTML"
        $message["body"]["content"] = $body
        $message["importance"] = $importance

        # Creating recipient table
        $recipient_table = @{}
        $recipient_table["to"] = "toRecipients"
        $recipient_table["cc"] = "ccRecipients"
        $recipient_table["bcc"] = "bccRecipients"
        
        Try {
            # Setting recipients
            foreach ($recipient_type in $recipient_table.Keys) {
                If ($PSBoundParameters.ContainsKey($recipient_type)) {
                    # Setting recipients
                    $message[$recipient_table[$recipient_type]] = @(Set-CAIQRecipientArray -Recipients $PSBoundParameters[$recipient_type])
                
                }
            }

            # Setting attachments
            If ($PSBoundParameters.ContainsKey("Attachments")) {
                $message["attachments"] = @(Set-CAIQAttachmentArray -Attachments $attachments)

            }
        } Catch {
            Write-Error $_ -ErrorAction Stop
        
        }

        # Setting the message key
        $mail_message["message"] = $message

        # Setting the Invoke-MgGraphRequest parameters
        $invoke_graph_params = @{}
        $invoke_graph_params["Uri"] = "$script:graph_endpoint/v1.0/users/$from/sendMail"
        $invoke_graph_params["Method"] = "Post"
        $invoke_graph_params["Body"] = $mail_message | ConvertTo-Json -Depth 4
        $invoke_graph_params["ContentType"] = "application/json"

    } Process {
        Try {
            # Sending the message
            Invoke-MgGraphRequest @invoke_graph_params
        } Catch {
            Write-Error $_
        
        }
    } End {

    }
} 