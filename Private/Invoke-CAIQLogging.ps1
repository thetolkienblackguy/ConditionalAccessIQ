Function Invoke-CAIQLogging {
    <#
        .SYNOPSIS
        This function creates a standardize logging experience. It is designed to streamline logging 
        specifically in situations where you would like to log events to a file as well as the console.
    
        .DESCRIPTION
        Use this function for script logging.  
    
        .PARAMETER Message
        Specifies Message
    
        .PARAMETER LogFile
        Specifies LogFile
    
        .PARAMETER WriteOutput
        Specifies WriteOutput
    
        .PARAMETER ForegroundColor
        Specifies ForegroundColor
    
        .EXAMPLE
        Invoke-CAIQLogging -Message "The change to user john.doe failed." -LogFile .\ADChange.log -WriteOutPut -ForegroundColor Red
      
        .INPUTS
        System.String

        .OUTPUTS
        System.String

    #>
    [CmdletBinding()]
    param (        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [string]$Logfile,
        [Parameter(Mandatory=$false)]
        [switch]$WriteOutput,
        [Parameter(Mandatory=$false)]
        [ValidateSet(
            "Black", "Blue", "Cyan", "DarkBlue", "DarkCyan", "DarkGray", 
            "DarkGreen", "DarkMagenta", "DarkRed", "DarkYellow", "Gray",
            "Green", "Magenta", "Red", "Yellow", "White"

        )]
        [string]$ForegroundColor = "Yellow"

    )
    Begin {
        $message = "$("[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)) $message"
        $parent_path = Split-Path $logfile -Parent
        If (!(Test-Path $parent_path)) {
            New-Item -Path $parent_path -ItemType Directory -Force | Out-Null
        
        }
    } Process {
        $message | Out-File $logFile -Append

    } End {
        If ($writeOutput.IsPresent) {
            If ($host.Name -eq "Default Host") {
                Write-Output $message

            } Else {
                Write-Host $message -ForegroundColor $foregroundColor -BackgroundColor Black
            
            }
        }
    }
}