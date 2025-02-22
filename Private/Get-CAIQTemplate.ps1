Function Get-CAIQTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateName,
        [Parameter(Mandatory=$false)]
        [string]$TemplatePath = "$($script:template_path)"
    
    )
    $template = Join-Path -Path $templatePath -ChildPath $templateName
    If (Test-Path -Path $template -PathType Leaf) {
        Try {
            Get-Content -Path $template -Raw
        
        } Catch {
            Write-Error "Error getting template $($templateName): $_" -ErrorAction Stop
        }
    } Else {
        throw "Template $($templateName) not found in $($templatePath)"
    
    }
}