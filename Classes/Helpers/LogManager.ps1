class LogManager {
    <#
        .SYNOPSIS
        A class for logging messages to a file and to the console.
        
        .DESCRIPTION
        The LogManager class provides a simple way to log messages to a file.
        
        .PARAMETER LogFile
        The path to the log file.
        
        .PARAMETER WriteOutput
        Whether to write the log messages to the console.
        
        .PARAMETER Verbose
        Whether to log verbose messages.

        .PARAMETER IsInteractive
        Whether the script is running in an interactive session.
        
        .EXAMPLE
        $log_manager = [LogManager]::new("C:\Logs\LogFile.log", $true, $false)
        
        .EXAMPLE
        $log_manager.Initialize("Hello, world!")
    
    #>
    [string]$LogFile
    [bool]$WriteOutput = $true
    [bool]$Verbose = $false
    [bool]$IsInteractive = $true
    
    # Constructor
    LogManager([string]$logFile, [bool]$writeOutput, [bool]$verbose) {
        $this.LogFile = $logFile
        $this.WriteOutput = $writeOutput
        $this.Verbose = $verbose
        
        # Ensure log directory exists
        $this.ValidateLogFile()
    
    }

    # Method to validate and create the log file if it doesn't exist
    hidden [void]ValidateLogFile() {
        # Create the log directory if it doesn't exist
        $log_path = [System.IO.Path]::GetDirectoryName($this.LogFile)
        If (![System.IO.Directory]::Exists($log_path)) {
            [System.IO.Directory]::CreateDirectory($log_path) | Out-Null
        
        }
        
        # Check if the log file exists and create it if it doesn't
        If (![System.IO.File]::Exists($this.LogFile)) {
            [System.IO.File]::Create($this.LogFile).Close()
        
        }
    }
    
    # Method to format the message with timestamp
    hidden [string]FormatLogMessage([string]$message, [string]$logLevel = "Information") {
        # Add a timestamp to the message
        $timestamp = [string]::Format("[{0:MM/dd/yy} {0:HH:mm:ss}]", [System.DateTime]::Now)
        return "$timestamp $("[$logLevel]") $message"
    
    }
    
    # Method to write message to log file
    hidden [void]WriteToLogFile([string]$message) {
        [System.IO.File]::AppendAllText($this.LogFile, "$message`r`n")
    
    }
    
    # Method to write message to console with specified color and reset after
    hidden [void]WriteColoredConsoleMessage([string]$message, [System.ConsoleColor]$foregroundColor, [System.ConsoleColor]$backgroundColor) {
        # Store original colors
        $original_color = [System.Console]::ForegroundColor
        $original_bg_color = [System.Console]::BackgroundColor
        
        # Set new colors
        [System.Console]::ForegroundColor = $foregroundColor
        [System.Console]::BackgroundColor = $backgroundColor
        
        # Write the message
        [System.Console]::WriteLine($message)
        
        # Reset to original colors
        [System.Console]::ForegroundColor = $original_color
        [System.Console]::BackgroundColor = $original_bg_color
    
    }
    
    # Method to convert string color name to ConsoleColor enum
    hidden [System.ConsoleColor]ParseConsoleColor([string]$colorName) {
        try {
            return [System.Enum]::Parse([System.ConsoleColor], $colorName)
        
        } catch {
            # Default to White if color parsing fails
            return [System.ConsoleColor]::White
        
        }
    }
    
    # Method to write message to console if enabled
    hidden [void]WriteToConsole([string]$message, [string]$foregroundColor) {
        # Use Console for output instead of Write-Host/Write-Output
        If (!$this.IsInteractive) {
            # Write-Output - writes to the success output stream
            Write-Output $message
        
        } Else {
            # Convert string color to ConsoleColor enum and write colored message
            $console_color = $this.ParseConsoleColor($foregroundColor)
            $this.WriteColoredConsoleMessage($message, $console_color, [System.ConsoleColor]::Black)
        
        }
    }
    
    # Method to log a message to the log file and console
    hidden [void]Log([string]$message, [string]$logLevel = "Information", [string]$color = "Yellow", [bool]$respectVerbose = $false) {
        # Skip if verbose is required but not enabled
        if ($respectVerbose -and !$this.Verbose) { 
            return 
        
        }
        
        # Format the message and write to log file and console
        $formatted_message = $this.FormatLogMessage($message, $logLevel)
        $this.WriteToLogFile($formatted_message)
        If ($this.WriteOutput) {
            $this.WriteToConsole($formatted_message, $color)
        
        }
    }
    
    # Method to log an initialize message
    [void]InitializeLog([string]$message) {
        $this.Log($message, "Initialize", "Yellow", $false)
    
    }
    
    # Method for backward compatibility before we explicitly added the WriteInfo method
    [void]Write([string]$message) {
        $this.WriteInfo($message)
    
    }
    
    # Method to log an info message
    [void]WriteInfo([string]$message) {
        $this.Log($message, "Information", "Yellow", $true)
    
    }
    
    # Method to log a success message
    [void]WriteSuccess([string]$message) {
        $this.Log($message, "Success", "Green", $true)
    
    }
    
    # Method to log an error message
    [void]WriteError([string]$message) {
        $this.Log($message, "Error", "Red", $false)
    
    }
    
    # Method to log a warning message
    [void]WriteWarning([string]$message) {
        $this.Log($message, "Warning", "Yellow", $false)
    
    }
    
    # Method to log a finalize message
    [void]FinalizeLog([string]$message) {
        $this.Log($message, "Finalize", "Cyan", $false)
    
    }
}