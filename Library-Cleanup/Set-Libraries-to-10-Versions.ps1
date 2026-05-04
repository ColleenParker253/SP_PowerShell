# Uninstall modern PnP.PowerShell module if installed
if (Get-Module -ListAvailable -Name PnP.PowerShell) {
    Write-Host "Uninstalling modern PnP.PowerShell module..."
    Uninstall-Module -Name PnP.PowerShell -AllVersions -Force -ErrorAction SilentlyContinue
}

# Install legacy SharePointPnPPowerShellOnline module
$legacyModule = "SharePointPnPPowerShellOnline"
$legacyVersion = "3.29.2101.0"

if (-not (Get-Module -ListAvailable -Name $legacyModule)) {
    Write-Host "."Installing $legacyModule version $legacyVersion..
    Install-Module -Name $legacyModule -RequiredVersion $legacyVersion -Scope CurrentUser -Force
}

# Import the legacy module
Import-Module SharePointPnPPowerShellOnline

# Define your SharePoint site URL
$siteUrl = "https://questnutrition.sharepoint.com/sites/fpaa"

# Connect using legacy web login (supports MFA)
Connect-PnPOnline -Url $siteUrl -UseWebLogin  -WarningAction Ignore'

# Get all lists in the site
$lists = Get-PnPList

foreach ($list in $lists) {
    # Check if the list is a document library (BaseTemplate 101)
    if ($list.BaseTemplate -eq 101) {
        Write-Host "Updating versioning settings for library: $($list.Title)"

        # Set versioning limit to 5 major versions
        Set-PnPList -Identity $list.Title `
            -EnableVersioning $true `
            -MajorVersions 5
    }
}
