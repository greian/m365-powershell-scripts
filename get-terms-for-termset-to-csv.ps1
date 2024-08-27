############################################################################
# Description: This script exports all terms from a term set to a CSV file.
############################################################################

param(
  [string]$siteUrl = "https://[tenant].sharepoint.com/sites/[sitename]",
  [string]$termGroupName = "[Term gruoup name]", # Example: "Company Taxonomy"
  [string]$termSetName = "[Term set name]", # Example: "Organisation Units"
  [string]$csvPath = ".\terms\[filename].csv"
)


# Connect to SharePoint Online
Connect-PnPOnline -Url $siteUrl -Interactive

# Retrieve the Term Set
$termGroup = Get-PnPTermGroup -Identity $termGroupName
$termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $termGroup

# Retrieve all terms from the term set
$terms = Get-PnPTerm -TermSet $termSet -TermGroup $termGroup -Recursive

# Prepare the data for export
$exportData = @()
foreach ($term in $terms) {
    $exportData += New-Object PSObject -Property @{
        "TermId" = $term.Id
        "TermName" = $term.Name
        "TermNewName" = $term.Name # Use this column to store a new term name
    }
}

# Export the data to a CSV file
$exportData | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "Terms have been exported to $csvPath"