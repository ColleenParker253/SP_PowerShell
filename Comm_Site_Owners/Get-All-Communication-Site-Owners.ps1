Connect-SPOService -Url https://<tenantname>-admin.sharepoint.com

# Create an empty array to store the output
$output = @()

# Get all site collections
$x = Get-SPOSite -Template "SITEPAGEPUBLISHING#0"  # Filter by Communication Site Template

# Loop through each site collection
foreach ($y in $x)
{
    # Write the site collection URL to the console in yellow
    Write-Host $y.Url -ForegroundColor "Yellow"

    # Try to get the site groups for the site collection
    try
    {
        $z = Get-SPOSiteGroup -Site $y.Url
    }
    # Catch any errors and display the message in red
    catch
    {
        Write-Host $_.Exception.Message -ForegroundColor "Red"
        # Continue to the next iteration of the loop
        continue
    }

    # Loop through each site group
    foreach ($a in $z)
    {
        # Get the Owners group details for the site collection and group name
        try
        {
            $b = Get-SPOSiteGroup -Site $y.Url $a.Title -Filter \
'Title - like "*Owner*"'
        }
        # Catch any errors and display the message in red
        catch
        {
            Write-Host $_.Exception.Message -ForegroundColor "Red"
            # Continue to the next iteration of the loop
            continue
        }

        # Write the site group name to the console in cyan
        Write-Host $b.Title -ForegroundColor "Cyan"

        # Get the users in the site group and write them to the console
        $b | Select-Object -ExpandProperty Users | Write-Host

        # Add the site collection URL, site group name, and users to the output array
        $output += $y.Url, $b.Title, ($b | Select-Object -ExpandProperty Users)

        # Write an empty line to the console
        Write-Host
    }
}

# Write the output array to a CSV file, using a relative path and appending to the file
$output | Out-File c:\Users\<username>\CommSiteOwners.csv -Append
