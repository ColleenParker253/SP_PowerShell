# === CONFIGURATION SET YOUR OWN ADDRESS FOR THE FILE ===
$dryRun = $true  # Set to $false to actually delete versions
$logPath = "C:\temp\Logs\<NAME OF SITE>.csv"
$siteaddress = "https://<TENANT>/sites/<site>"
$libraryname = "Shared Documents"

# Initialize log file
if (!(Test-Path $logPath)) {
    "FileName,VersionLabel,FileSizeBytes,Deleted,Timestamp" | Out-File -FilePath $logPath
}

# Connect using web login
Connect-PnPOnline -Url $siteaddress -UseWebLogin

# Get all items in the Shared Documents library
$items = Get-PnPListItem -List $libraryname -PageSize 100

foreach ($item in $items) {
    try {
        if ($item.FieldValues.FileRef -and $item.FileSystemObjectType -eq "File") {
            $file = Get-PnPProperty -ClientObject $item -Property File

            if ($file -ne $null) {
                $fileSize = $file.Length
                $versions = Get-PnPProperty -ClientObject $file -Property Versions

                if ($versions -ne $null -and $versions.Count -gt 10) {
                    $versionCount = $versions.Count
                    $versionsToDelete = $versionCount - 10

                    Write-Host "`nFile: $($file.Name) has $versionCount versions. Preparing to delete $versionsToDelete oldest versions..."

                    for ($i = $versionsToDelete - 1; $i -ge 0; $i--) {
                        $version = $versions[$i]
                        $logEntry = "$($file.Name),$($version.VersionLabel),$fileSize,$(!$dryRun),$(Get-Date -Format o)"
                        $logEntry | Out-File -FilePath $logPath -Append

                        if ($dryRun) {
                            Write-Host "[Dry Run] Would delete version $($version.VersionLabel)"
                        } else {
                            Write-Host "Deleting version $($version.VersionLabel)"
                            $version.DeleteObject()
                        }
                    }

                    if (-not $dryRun) {
                        Invoke-PnPQuery
                    }
                }
            }
        } else {
            Write-Host "Skipping non-file item: $($item.FieldValues.FileLeafRef)"
        }
    } catch {
        Write-Warning "Error processing item $($item.FieldValues.FileLeafRef): $_"
    }
}
