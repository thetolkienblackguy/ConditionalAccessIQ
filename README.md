# ConditionalAccessIQ

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ConditionalAccessIQ)](https://www.powershellgallery.com/packages/ConditionalAccessIQ)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/ConditionalAccessIQ)](https://www.powershellgallery.com/packages/ConditionalAccessIQ)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ConditionalAccessIQ)](https://www.powershellgallery.com/packages/ConditionalAccessIQ)

ConditionalAccessIQ provides robust tools with simple, easy-to-use functions for monitoring Microsoft Entra ID (formerly Azure AD) Conditional Access policies. In its current form, the module addresses two specific needs:

1. **Change Tracking**: Identifying who made policy modifications, what was changed, and maintaining documentation of policy evolution
2. **Break Glass Account Verification**: Ensuring emergency access accounts are properly excluded from Conditional Access policies

- **Alpha Version**: This is a work in progress, while I have deployed this in to production environments, there may be some bugs and issues. Your feedback is important to me, please share any issues you find. The code was developed in a way to be able to dynamically adjust to new conditional access policies features that are released, however, that may not always be the case.

> **Future Development**: While the module currently offers these two key functions, the plan is to add more capabilities in the future. If you have suggestions for additional features, please share them!

## Report & Assessment Capabilities

The module provides interactive HTML-based visualizations and assessments:

### Change Comparison View

- Side-by-side comparisons of policy changes
- Complete audit information including who made changes
- Automatic JSON backups of each version

![Change Tracking View](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/changes.png)

### Policy Information View

- Audit log id that contains the full audit log entry
- Modified, Created, and Deleted by wnd time

![Policy Information View](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/policy_information.png)

### Break Glass Assessment Dashboard

- Shows which break glass accounts are excluded from Conditional Access policies
- Identifies policies that don't have proper exclusions configured
- Provides links to quickly update policies in Entra portal

![Break Glass Assessment Dashboard](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/break_glass_assessment.png)

> **Version:** 0.1.0  
> **Author:** Gabriel Delaney ([GitHub](https://github.com/thetolkienblackguy))  
> **Company:** Phoenix Horizons LLC  

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Authentication Setup](#authentication-setup)
5. [Usage Guide](#usage-guide)
6. [Known Limitations](#known-limitations)

## Features

- 🔄 **Change Tracking & Version Control**
  - Policy version history
  - Automatic JSON backups
  - Side-by-side change comparison
  - Detailed audit trail

- 🛡️ **Break Glass CA Policy Exclusion Verification**
  - Policy exclusion checking
  - Visual dashboard of exclusion status
  - Account-by-policy matrix view
  - Quick links to Entra portal for remediation

- 📊 **Visual Reporting**
  - Interactive HTML dashboards
  - Property-level change visualization
  - Timeline tracking
  - Identity resolution

- 🔍 **Detailed Analysis**
  - Property-level changes
  - User tracking
  - Application mapping
  - Role resolution

- 📨 **Reporting Options**
  - HTML reports
  - Email notifications
  - JSON exports
  - Audit archiving

## Prerequisites

### Required Components

- PowerShell 5.1 or PowerShell 7.x
- Microsoft.Graph.Authentication module (automatically installed)

### Microsoft Graph Permissions

#### Required Permissions

- Policy.Read.All
- AuditLog.Read.All
- Directory.Read.All
- Application.Read.All
- GroupMember.Read.All (required for break glass assessment)
- Mail.Send (only if using email functionality)

#### Role Requirements

When using delegated permissions (as opposed to application permissions), you need:

- **Global Reader**: This role provides all necessary permissions for the tool to function

## Installation

```powershell
# Install from PowerShell Gallery
Install-Module -Name ConditionalAccessIQ -Scope CurrentUser -MinimumVersion 0.1.0

# Import the module
Import-Module ConditionalAccessIQ
```

## Authentication Setup

### Interactive Authentication

```powershell
# Connect with required scopes
Connect-MgGraph -Scopes @(
    "Policy.Read.All",
    "AuditLog.Read.All",
    "Directory.Read.All",
    "Application.Read.All",
    "GroupMember.Read.All"
)
```

### App Registration (Required for Email/Application Permissions)

1. Navigate to [Entra Portal](https://entra.microsoft.com) > App Registrations
2. Create New Registration:
   - Name: "ConditionalAccessIQ"
   - Supported account type: Single tenant
   - Click Register
   ![App Registration](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/app_registration.png)

3. Add Required Permissions:
   - Click "API Permissions"
   - Add Microsoft Graph permissions:
     - Policy.Read.All (Application)
     - AuditLog.Read.All (Application)
     - Directory.Read.All (Application)
     - Application.Read.All (Application)
     - GroupMember.Read.All (Application)
     - Mail.Send (Application, if using email - see note below)
   - Grant admin consent

   > **Note on Mail.Send Permission**: When configuring Mail.Send, you should specify which mailbox the application can access. See [Microsoft's guidance on limiting mailbox access](https://learn.microsoft.com/en-us/graph/auth-limit-mailbox-access) for configuration details.

   ![Graph API Permissions](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/graph_api_permissions.png)

4. Create Secret or Certificate:
   - Under "Certificates & secrets"
   - Create new client secret or upload certificate
   - Save credentials securely

5. Connect Using App Credentials:

```powershell
# Using client secret
$client_id = "your-client-id"
$client_secret = "your-client-secret" | ConvertTo-SecureString -AsPlainText -Force
$client_secret_credential = New-Object System.Management.Automation.PSCredential($client_id, $client_secret)
$tenant_id = "your-tenant-id"

Connect-MgGraph -ClientSecretCredential $client_secret_credential -TenantId $tenant_id

# Or using certificate
Connect-MgGraph -ClientId $client_id -CertificateThumbprint "cert-thumbprint" -TenantId $tenant_id
```

## Usage Guide

### 1. Change Tracking

Use `Invoke-CAIQ` to track Conditional Access policy changes:

```powershell
# Monitor changes for last 24 hours (default)
Invoke-CAIQ

# Monitor changes for specific date range
$start_date = (Get-Date).AddDays(-7).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$end_date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Invoke-CAIQ -StartDate $start_date -EndDate $end_date

# Custom output path
Invoke-CAIQ -OutputPath "C:\CAIQReports"

# Custom report name
Invoke-CAIQ -FileName "CA_Changes_Report.html"

# Generate without opening browser
Invoke-CAIQ -InvokeHtml:$false
```

### 2. Break Glass CA Policy Exclusion Verification

Use `Invoke-CAIQBreakGlassAssessment` to verify emergency access accounts are properly excluded from Conditional Access policies:

```powershell
# Check single break glass account
Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com"

# Check multiple break glass accounts
Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com","emergency@contoso.com"

# Custom output path
Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com" -OutputPath "C:\CAIQReports"

# Custom report name
Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com" -FileName "BreakGlass_Assessment.html"

# Generate without opening browser
Invoke-CAIQBreakGlassAssessment -UserId "breakglass@contoso.com" -InvokeHtml:$false
```

### 3. Email Notifications

Send reports to stakeholders using `Send-CAIQMailMessage`:

```powershell
Send-CAIQMailMessage -To "security@contoso.com" -From "caiq@contoso.com" -Subject "CA Policy Changes" -Body "Please review the attached report." -Attachments "$($PWD)\ConditionalAccessIQ\CA_Changes_Report.html"
```

## Automation Example

Automating both policy change tracking and break glass exclusion verification:

```powershell
# Install and import if needed
Import-Module ConditionalAccessIQ

# Connect using certificate auth (recommended for automation)
Connect-MgGraph -ClientId $client_id -CertificateThumbprint "cert-thumbprint" -TenantId $tenant_id

# Run report for last 24 hours
Invoke-CAIQ -InvokeHtml:$false

# The report path
$html_path = "$($PWD)\ConditionalAccessIQ\Conditional_Access_Intelligence.html"

# If the report exists get the content of it, if not, exit. 
If ((Test-Path $html_path -PathType Leaf)) {
    $html = Get-Content -Path $html_path -Raw
    
    # Email the report
    Send-CAIQMailMessage -To "jdoe@contoso.com" -From "thetolkienblackguy@contoso.com" -Subject "Daily CA Changes Report" -Body $html -Attachments $html_path

}

```

```PowerShell
# Run break glass assessment
$bg_accounts = @("breakglass@contoso.com", "emergency@contoso.com")
Invoke-CAIQBreakGlassAssessment -UserId $bg_accounts -InvokeHtml:$false

# The break glass report path
$bg_report_path = "$($PWD)\ConditionalAccessIQ\BreakGlass_CA_Policy_Exclusion_Assessment.html"

# If the report exists get the content of it
If ((Test-Path $bg_report_path -PathType Leaf)) {
    $bg_html = Get-Content -Path $bg_report_path -Raw
    
    # Email the break glass assessment report
    Send-CAIQMailMessage -To "jdoe@contoso.com" -From "thetolkienblackguy@contoso.com" -Subject "Break Glass CA Policy Assessment" -Body $bg_html -Attachments $bg_report_path
}
```

You can schedule this script using:

- Windows Task Scheduler
- Azure Automation

## Output Formats

ConditionalAccessIQ generates several output types:

### Interactive Reports

- Policy change visualization with side-by-side comparison
- Break glass exclusion verification dashboard
- Visual indication of policies needing attention
- Timeline of policy changes

### Policy Documentation

- Automatic JSON backups of policy versions
- Complete policy configurations
- Version history with change details
- Historical documentation for audit needs

### Change Records

- Details on who made changes
- When changes were made
- Before and after policy state
- Links to relevant audit logs

### Email Reports

- HTML-formatted reports for review
- Break glass exclusion status updates
- Policy change notifications
- Attachment support for offline viewing

## Known Limitations

### Audit Log Access

- Limited to 30-day history
- Regular monitoring recommended for complete history

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
