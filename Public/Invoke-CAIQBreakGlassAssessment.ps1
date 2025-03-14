Function Invoke-CAIQBreakGlassAssessment {
    <#
        .SYNOPSIS
        Creates a dashboard showing break glass accounts and their conditional access policy exclusions.

        .DESCRIPTION
        It runs an assessment of whether specified break glass accounts are excluded from all 
        Conditional Access policies and generates an HTML report with the findings.

        .PARAMETER BreakGlassAccount
        The break glass accounts to check. This can be either the User Principal Name (UPN) or Object ID.

        .PARAMETER OutputPath
        The path where the HTML report will be saved.

        .PARAMETER FileName
        The name of the HTML report file.

        .PARAMETER Title
        The title of the HTML report.

        .PARAMETER Logfile
        The path to the log file.

        .PARAMETER InvokeHtml
        If specified, opens the HTML report after creation.

        .EXAMPLE
        Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com","emergency@contoso.com"

        .EXAMPLE
        Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com" -OutputPath "C:\Reports" -InvokeHtml

        .INPUTS
        System.String[]
        System.String
        System.Automation.SwitchParameter

        .OUTPUTS
        System.Object

    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("BG","BreakGlassAccounts","Id","Upn")]
        [string[]]$UserId,
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$($PWD)\ConditionalAccessIQ",
        [Parameter(Mandatory=$false)]
        [string]$FileName = "BreakGlass_CA_Policy_Exclusion_Assessment.html",
        [Parameter(Mandatory=$false)]
        [string]$Title = "Break Glass CA Policy Exclusion Assessment",
        [Parameter(Mandatory=$false)]
        [string]$Logfile = "$($outputPath)\Logs\Invoke-CAIQBreakGlassAssessment_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log",
        [Parameter(Mandatory=$false)]
        [bool]$InvokeHtml = $true
    
    )
    Begin {
        # Setting the default parameter values
        $PSDefaultParameterValues = @{}
        $PSDefaultParameterValues["Invoke-CAIQLogging:Logfile"] = $Logfile
        $PSDefaultParameterValues["Invoke-CAIQLogging:WriteOutput"] = $true
    
    } Process {
        # Run the break glass assessment
        Invoke-CAIQLogging -Message "Starting break glass CAIQ exclusion assessment" 
        
        Try {
            # Run the assessment
            $assessment_results = Get-CAIQBreakGlassAssessment -UserId $userId
            Invoke-CAIQLogging -Message "Break glass assessment completed successfully" -ForegroundColor Green

        } Catch {
            Invoke-CAIQLogging -Message "Error during break glass assessment: $_" -ForegroundColor Red
            Write-Error -Message $_ -ErrorAction Stop
        
        }
        
        # Generate the HTML report
        Invoke-CAIQLogging -Message "Generating HTML report" 
        
        Try {

            # New-CAIQBreakGlassReport parameters
            $report_params = @{}
            $report_params["DataSet"] = $assessment_results
            $report_params["OutputPath"] = $OutputPath
            $report_params["Title"] = $Title
            $report_params["FileName"] = $FileName
            
            # Generate the HTML report
            $html_report = New-CAIQBreakGlassExclusionDashboard @report_params
            Invoke-CAIQLogging -Message "HTML report generated successfully at: $($html_report.Path)" -ForegroundColor Green
            

        } Catch {
            Invoke-CAIQLogging -Message "Error generating HTML report: $_" -ForegroundColor Red
            Write-Error -Message $_ -ErrorAction Stop
        
        }
    } End {
        # Open the HTML report if specified
        if ($invokeHtml) {
            Invoke-Item $html_report.Path
        
        }
    }
}