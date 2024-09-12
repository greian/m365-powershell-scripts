##############################################################################################
# This script updates the content type of all document libraries in all sites in a hub
# The content type is synced from the content type hub
##############################################################################################

# Input parameters
param(
  [string]$oldCTName = "[old content type name]", # The name of the content type to be replaced
  [string]$newCTName = "[new content type name]", # The name of the new content type to be added
  [string]$adminSiteUrl = "[admin site url]", # URL of the SharePoint Online Admin Center
  [string]$hubSiteUrl = "[hub site url]" # URL of the SharePoint hub site
)

# create a log type with the name of the script and a timestamp
$LogType = "sync-cth-to-sites-in-hub"
$LogTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$LogName = "$LogType-$LogTime.log"

# create a log file
$LogPath = ".\$LogName"
New-Item -Path $LogPath -ItemType File -Force | Out-Null

# Connect to the SharePoint Online Admin Center
Connect-PnPOnline -Url $adminSiteUrl -Interactive

# Get all sites connected to the hub site
$connectedSites = Get-PnPHubSiteChild -Identity $hubSiteUrl

# For each connected site
foreach ($siteUrl in $connectedSites) {

  # Connect to the SharePoint Online site
  Connect-PnPOnline -Url $siteUrl -Interactive

  # Log the site being processed
  Add-Content -Path $LogPath -Value "INFO: Processing site: $($siteUrl)"

  # Add the content type from the content type hub
  Add-PnPContentTypesFromContentTypeHub -ContentTypes "0x01010078E9E655DFC737409BE27204C3FF8637"
  Write-Host "Added content type to $($siteUrl)"
  Add-Content -Path $LogPath -Value "Added content type to $($siteUrl)"

  # Get all document libraries in the site
  $docLibraries = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 }

  # Foreach document library add the synced content type
  foreach ($docLibrary in $docLibraries) {
    
    # Log number of documents in the library
    $docCount = (Get-PnPListItem -List $docLibrary).Count    

    # Log the document library being processed
    Write-Host "Processing document library: $($docLibrary.Title) with $docCount documents"
    Add-Content -Path $LogPath -Value "INFO: Processing document library: $($docLibrary.Title) with $docCount documents"

    try {

      # Check if the list has a content type with the specified name
      $contentTypeOriginal = Get-PnPContentType -List $docLibrary -Identity $oldCTName -ErrorAction SilentlyContinue
      if ($null -eq $contentTypeOriginal) {
        Write-Host "INFO: Content type DocCenter Basdokument not found in $($docLibrary.Title)"
        continue
      }

      # Check if the list has a content type with the specified name
      $contentTypeNew = Get-PnPContentType -List $docLibrary -Identity $newCTName -ErrorAction SilentlyContinue

      if ($null -ne $contentTypeNew) {
        Write-Host "INFO: Content type ($newCTName) already exists in $($docLibrary.Title)"
        Add-Content -Path $LogPath -Value "INFO: Content type ($newCTName) already exists in $($docLibrary.Title)"
        continue
      }

      # Add the content type to the document library
      Add-PnPContentTypeToList -List $docLibrary -ContentType $newCTName
      Add-Content -Path $LogPath -Value "INFO: Added content type $($newCTName) to $($docLibrary.Title)"

      # Set the content type as the default content type
      try {
        Set-PnPDefaultContentTypeToList -List $docLibrary -ContentType $newCTName
        Add-Content -Path $LogPath -Value "INFO: Set content type $($newCTName) as default for $($docLibrary.Title)"
      } 
      catch { Add-Content -Path $LogPath -Value "ERROR: Failed to set content type $($newCTName) as default for $($docLibrary.Title): $_" }
    
      # Change the setting "allow management of content types" to false
      try {
        Set-PnPList -Identity $docLibrary -EnableContentTypes $false
        Add-Content -Path $LogPath -Value "INFO: Disabled management of content types in $($docLibrary.Title)"
      }
      catch { Add-Content -Path $LogPath -Value "ERROR: Failed to disable management of content types in $($docLibrary.Title): $_" }

    }
    catch {
      Write-Error "Failed to process document library $($docLibrary.Title): $_"
    }
    finally {
    }
  }

}
