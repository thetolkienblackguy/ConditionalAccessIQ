@{
    # Module metadata
    ModuleVersion       = "0.1.0"
    GUID                = "ae965c65-34a1-4e08-b34a-95dd363eaeb5"
    Author              = "Gabriel Delaney - gdelaney@phzconsulting.com | https://github.com/thetolkienblackguy"
    CompanyName         = "Phoenix Horizons LLC"
    Copyright           = "(c) Phoenix Horizons LLC. All rights reserved."
    Description         = "Module for tracking changes and monitoring Conditional Access Policies in Microsoft Entra Id"

    # Supported PowerShell editions
    PowerShellVersion   = "5.1"
    CompatiblePSEditions = @("Desktop", "Core")

    # Dependencies
    RequiredModules     = @("Microsoft.Graph.Authentication")

    # Module file paths
    RootModule          = "ConditionalAccessIQ.psm1"
    
    FunctionsToExport   = @(
        "Invoke-CAIQ", "Send-CAIQMailMessage", "Invoke-CAIQBreakGlassAssessment"

    )
    CmdletsToExport     = @()
    VariablesToExport   = "*"
    AliasesToExport     = "*"
    
    # Private Data
    PrivateData = @{
        PSData = @{
            Tags = @("ConditionalAccess", "EntraID", "AzureAD", "VersionControl")
            LicenseUri = "https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/LICENSE"
            ProjectUri = "https://github.com/thetolkienblackguy/ConditionalAccessIQ"
        }
    }
}