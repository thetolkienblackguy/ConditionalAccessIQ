class GraphMailClient {
    [GraphRequestClient]$GraphRequestClient
    hidden [hashtable]$MimeTypes

    GraphMailClient() {
        $this.GraphRequestClient = [GraphRequestClient]::new()
        $this.MimeTypes = $this.GetCommonMimeTypes()
    
    }
    
    # Created this class to map file extensions to MIME types as System.Web.MimeMapping does not work in PowerShell 7.x
    [string]GetMimeType([string]$path) {
        # Initialize default value
        $value = "application/octet-stream"

        # Get the extension of the file
        $extension = [System.IO.Path]::GetExtension($path).ToLower()

        # If the extension is already cached, return the value
        If ($this.MimeTypes.ContainsKey($extension)) {
            return $this.MimeTypes[$extension]
        
        }

        # If the extension is empty, return the default value
        if ([string]::IsNullOrEmpty($extension)) {
            $this.MimeTypes[$extension] = $value
            return $value
        
        }

        # Try to get the MIME type from the registry
        Try {
            $reg_key = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($extension)
            if ($reg_key -and $reg_key.GetValue("Content Type")) {
                $value = $reg_key.GetValue("Content Type").ToString()
                $this.MimeTypes[$extension] = $value
                return $value
            
            }
        } Catch {
            Write-Verbose "Error getting MIME type for $($extension): $_"
        
        }

        # Add the extension and value to the cache
        $this.MimeTypes[$extension] = $value
        return $value
    
    }

    hidden [hashtable]GetCommonMimeTypes() {
        $mime_types = @{}
        $mime_types[".txt"] = "text/plain"
        $mime_types[".csv"] = "text/csv"
        $mime_types[".pdf"] = "application/pdf"
        $mime_types[".doc"] = "application/msword"
        $mime_types[".docx"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        $mime_types[".xls"] = "application/vnd.ms-excel"
        $mime_types[".xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        $mime_types[".ppt"] = "application/vnd.ms-powerpoint"
        $mime_types[".pptx"] = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        $mime_types[".jpg"] = "image/jpeg"
        $mime_types[".jpeg"] = "image/jpeg"
        $mime_types[".png"] = "image/png"
        $mime_types[".gif"] = "image/gif"
        $mime_types[".bmp"] = "image/bmp"
        $mime_types[".ico"] = "image/x-icon"
        $mime_types[".webp"] = "image/webp"
        
        return $mime_types

    }

    # Method to build the recipient array
    [system.collections.generic.list[psobject]]BuildRecipientList([string[]]$recipients) {
        $recipient_array = [system.collections.generic.list[psobject]]::new()
        foreach ($recipient in $recipients) {
            # Check if the recipient is a valid email address
            If (!$this.IsEmailAddress($recipient)) {
                Write-Error "Invalid email address: $recipient"
                Continue

            }

            # Create the address table
            $address = @{}
            $address["address"] = $recipient

            # Create the recipient table
            $recipient_table = @{}
            $recipient_table["emailAddress"] = $address

            # Add the recipient table to the recipient array
            $recipient_array.Add($recipient_table)

        }
        return $recipient_array
    
    }

    # Method to build the attachment array
    [system.collections.generic.list[psobject]]BuildAttachmentList([string[]]$attachments) {
        $attachment_array = [system.collections.generic.list[psobject]]::new()
        foreach ($attachment in $attachments) {
            # Get the file info
            $attachment_file_info = [System.IO.FileInfo]::new($attachment)

            # Create the attachment table
            $attachment_table = @{}
            $attachment_table["@odata.type"] = "#microsoft.graph.fileAttachment"
            $attachment_table["name"] = [System.IO.Path]::GetFileName($attachment_file_info.FullName)
            $attachment_table["contentType"] = $this.GetMimeType($attachment_file_info.FullName)
            $attachment_table["contentBytes"] = [Convert]::ToBase64String([IO.File]::ReadAllBytes(($attachment_file_info).FullName))

            # Add the attachment table to the attachment array
            $attachment_array.Add($attachment_table)

        }
        return $attachment_array
    
    }

    # Method to validate string is an email address
    [bool]IsEmailAddress([string]$emailAddress) {
        # Check if the email address is valid
        If ([System.Net.Mail.MailAddress]::new($emailAddress).Address -eq $emailAddress) {
            Return $true

        }
        Return $false

    }

    # Method to validate the importance
    [bool]ValidateImportance([string]$importance) {
        If ($importance -notin @("Low", "Normal", "High")) {
            Return $false

        }
        Return $true

    }

    # Method to send a mail
    [void]SendMail(
                [string]$subject, [string]$body, [string]$from, [string[]]$to, [string[]]$cc, [string[]]$bcc, 
                [string[]]$attachments, [bool]$saveToSentItems = $true, [string]$importance = "Normal") {
        # Validate the importance
        If (!$this.ValidateImportance($importance)) {
            Write-Error "Invalid importance: $importance"
            Return

        }

        # Build the mail body
        $mail_body = $this.BuildMailBody($subject, $body, $to, $cc, $bcc, $attachments, $saveToSentItems, $importance) 

        # Invoke the request
        $this.GraphRequestClient.InvokeGraphPostRequest("users", @($from, "sendMail"), $mail_body)
            
    }

    # Method to build the mail body
    [hashtable]BuildMailBody(
            [string]$subject, [string]$body, [string[]]$to, [string[]]$cc, [string[]]$bcc, 
            [string[]]$attachments, [bool]$saveToSentItems = $true, [string]$importance = "Normal"
        
        ) {
        # Creating parent message hash table
        $mail_message = @{}
        $mail_message["message"] = ""
        $mail_message["saveToSentItems"] = $saveToSentItems
           
        # Creating message hash table
        $message = @{}
        $message["subject"] = $subject
        $message["body"] = @{}
        $message["body"]["contentType"] = "HTML"
        $message["body"]["content"] = $body
        $message["importance"] = $importance
        $message["attachments"] = $this.BuildAttachmentList($attachments)

        # Setting recipients
        $message["toRecipients"] = $this.BuildRecipientList($to)
        if ($cc) {
            $message["ccRecipients"] = $this.BuildRecipientList($cc)

        }
        if ($bcc) {
            $message["bccRecipients"] = $this.BuildRecipientList($bcc)

        }

        # Setting the message key
        $mail_message["message"] = $message

        # Sending the mail
        Return $mail_message

    }
}