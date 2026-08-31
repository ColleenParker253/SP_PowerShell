<#
.SYNOPSIS
Retrieves all SharePoint Online Communication Site Owners groups using PnP PowerShell.

.DESCRIPTION
Connects to SharePoint Online using Connect-PnPOnline, enumerates all Communication Sites,
retrieves each site's Owners group, prints results to the console, and exports a CSV file.

.PARAMETER TenantName
The tenant name portion of your SharePoint Online domain.
Example: "contoso" → https://contoso.sharepoint.com

.PARAMETER AdminUrl
Optional. If you prefer to specify the full admin URL manually.
If not provided, the script builds it using TenantName.

.PARAMETER OutputPath
Full path to the CSV file to be created.

.EXAMPLE
.\Get-AllCommunicationSiteOwners-PnP.ps1 -TenantName "contoso"

.EXAMPLE
.\Get-AllCommunicationSiteOwners-PnP.ps1 -TenantName "contoso" -OutputPath "C:\Reports\CommSiteOwners.csv"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TenantName,

    [string]$AdminUrl,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\CommSiteOwners.csv"
)

# Build admin URL if not provided
if (-not $AdminUrl) {
    $AdminUrl = "https://$TenantName-admin.sharepoint.com"
}

# Validate PnP.PowerShell module
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    Write-Host "PnP.PowerShell module not found. Install using: Install-Module PnP.PowerShell" -ForegroundColor Red
    return
}

Write-Host "Connecting to SharePoint Online Admin Center: $AdminUrl" -ForegroundColor Cyan
Connect-PnPOnline -Url $AdminUrl -Interactive

# Get all Communication Sites
Write-Host "Retrieving Communication Sites..." -ForegroundColor Cyan
$sites = Get-PnPTenantSite -Template "SITEPAGEPUBLISHING#0"

# Prepare output collection
$results = @()

foreach ($site in $sites) {

    Write-Host "`nProcessing site: $($site.Url)" -ForegroundColor Yellow

    # Connect to each site individually
    Connect-PnPOnline -Url $site.Url -Interactive

    # Get all groups for the site
    $groups = Get-PnPGroup

    # Find the Owners group (supports renamed groups containing "Owner")
    $ownersGroup = $groups | Where-Object { $_.Title -like "*Owner*" }

    if ($ownersGroup) {
        Write-Host "Owners Group: $($ownersGroup.Title)" -ForegroundColor Cyan

        # Get users in the Owners group
        $owners = Get-PnPGroupMembers -Identity $ownersGroup.Title

        if ($owners) {
            $ownerEmails = $owners.Email -join "; "
            Write-Host "Owners: $ownerEmails"
        }
        else {
            $ownerEmails = ""
            Write-Host "No owners found." -ForegroundColor Red
        }

        # Build output object
        $results += [PSCustomObject]@{
            SiteName = $site.Title
            SiteUrl  = $site.Url
            Owners   = $ownerEmails
        }
    }
    else {
        Write-Host "No Owners group found for this site." -ForegroundColor Red

        $results += [PSCustomObject]@{
            SiteName = $site.Title
            SiteUrl  = $site.Url
            Owners   = ""
        }
    }
}

# Export results
Write-Host "`nExporting results to $OutputPath..." -ForegroundColor Cyan
$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "`nCompleted." -ForegroundColor Green
