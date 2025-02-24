# ConditionalAccessIQ

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ConditionalAccessIQ)](https://www.powershellgallery.com/packages/ConditionalAccessIQ)
[![PSGallery Platform](https://img.shields.io/powershellgallery/p/ConditionalAccessIQ)](https://www.powershellgallery.com/packages/ConditionalAccessIQ)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ConditionalAccessIQ)](https://www.powershellgallery.com/packages/ConditionalAccessIQ)

Maintaining visibility into Conditional Access Policy changes in Microsoft Entra ID (formerly Azure AD) can be challenging. Whether tracking down who made a specific change, understanding what was modified, or maintaining documentation of policy evolution.

ConditionalAccessIQ streamlines this process by providing automatic version control, change tracking, and visual comparisons of your Conditional Access Policies. The tool enables administrators to continuously monitor for changes, maintains a detailed history of changes, and generates clear, interactive reports showing exactly what was modified, when, and by whom.

- **Alpha Version**: This is a work in progress, while I have deployed this in to production environments, there may be some bugs and issues. Your feedback is important to me, please share any issues you find. The code was developed in a way to be able to dynamically adjust to new conditional access policies features that are released, however, that may not always be the case.

## Report Previews

Every policy change is documented with an interactive HTML report that shows:

### Change Comparison View

- Side-by-side comparisons of policy changes
- Complete audit information including who made changes
- Automatic JSON backups of each version

![Change Tracking View](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/changes.png)

### Policy Information View

- Audit log id that contains the full audit log entry
- Modified, Created, and Deleted by wnd time

![Policy Information View](https://github.com/thetolkienblackguy/ConditionalAccessIQ/blob/main/Imgs/policy_information.png)

> **Version:** 0.0.1  
> **Author:** Gabriel Delaney ([GitHub](https://github.com/thetolkienblackguy))  
> **Company:** Phoenix Horizons LLC  

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Authentication Setup](#authentication-setup)
5. [Usage Guide](#usage-guide)
6. [Sample Output](#sample-output)
7. [Known Limitations](#known-limitations)

## Features

- 🔄 **Version Control**
  - Policy version history
  - Automatic JSON backups
  - Change comparison
  - Audit trail tracking

- 📊 **Change Visualization**
  - Interactive HTML report
  - Before/after comparisons
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
- Mail.Send (only if using email functionality)

#### Role Requirements

When using delegated permissions (as opposed to application permissions), you need:

- **Global Reader**: This role provides all necessary permissions for the tool to function

## Installation

```powershell
# Install from PowerShell Gallery
Install-Module -Name ConditionalAccessIQ -Scope CurrentUser

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
    "Application.Read.All"
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

### Invoke-CAIQ

Monitor and track Conditional Access policy changes:

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

### Send-CAIQMailMessage

Send email notifications about policy changes:

```powershell
Send-CAIQMailMessage -To "security-team@contoso.com" -From "reports@contoso.com" -Subject "CA Policy Changes" -Body "Please review the attached report." -Attachments "C:\CAIQReports\CA_Changes_Report.html"
```

### Recommended Automation

Since Conditional Access changes are critical to security, it's recommended to automate this tool to run daily. Here's an example PowerShell script you could schedule:

```powershell
# Install and import if needed
Import-Module ConditionalAccessIQ

# Connect using certificate auth (recommended for automation)
Connect-MgGraph -ClientId $client_id -CertificateThumbprint "cert-thumbprint" -TenantId $tenant_id

# Run report for last 24 hours
Invoke-CAIQ -OutputPath $PWD

# Use the html report as the body of the email
$html = Get-Content "$($PWD)\Conditional_Access_Intelligence.html" -Raw

# Email the report
Send-CAIQMailMessage -To "security-team@contoso.com" -From "reports@contoso.com" -Subject "Daily CA Changes Report" -Body $html -Attachments "$($PWD)\Conditional_Access_Intelligence.html"
```

You can schedule this script using:

- Windows Task Scheduler
- ~~Azure Automation~~ Currently not functioning.  

## Sample Output

The tool provides several output formats:

### Interactive Reports

- Policy change timeline
- Visual before/after comparisons
- Change highlighting
- User and identity resolution
- Version tracking

### JSON Backups

- Automatic version backups
- Full policy configurations
- Restoration capability
- Historical documentation

### HTML Reports

- Interactive timelines
- Searchable changes
- Detailed audit information
- Email-ready format

### Audit Archives

- Complete change history
- User activity tracking
- Modification timestamps
- Service principal recording

## Known Limitations

**Audit Log Access**

- Limited to 30-day history
- Regular monitoring recommended for complete history

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
