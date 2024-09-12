### Find all Power Automate flows created by a specific user in a Power Platform environment

param (
    [string]$userId, # The user ID of the user you want to find flows for
    [string]$environmentName # The name of the environment you want to search in
)

### To find the userId, you can use the AzureAD module: ###
# Install-Module AzureAD
# Connect-AzureAD
# Get-AzureADUser -ObjectId [email]

#### If you need to find the environment name, you can use the PowerApps module: ###
# For example: Get-AdminPowerAppEnvironment *default*

# Check if the module is already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.PowerApps.Administration.PowerShell)) {
  Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Force
}

# Log in (you need to be a Power Platform Administrator via PIM)
Add-PowerAppsAccount

# Export to CSV file
$flows = Get-AdminFlow -EnvironmentName $environmentName 
### If you want to export to a csv file add: | Export-Csv -Path "C:\dev\PowerAutomateFlows.csv" -NoTypeInformation

# Find all flows created by a specific user
foreach ($flow in $flows) {

  # Get flow details, including the owner
  $flowDetails = Get-AdminFlow -EnvironmentName $environmentName -FlowName $flow.FlowName
  
  # Check if the user email is in the owner details
  if ($flowDetails.displayName -and $flowDetails.CreatedBy -and $flowDetails.CreatedBy.userId -eq $userId) {
    Write-Output "Flow Name: $($flow.DisplayName), Flow ID: $($flow.FlowName)"
  }

}

### If you want to add another user as the owner of the flow, you can use the Set-FlowOwnerRole cmdlet ###
# Set-FlowOwnerRole -EnvironmentName $environmentName -FlowName [YourFlowID] -PrincipalType User -RoleName CanEdit -UserId $userId


# $userId = 6e7d37c4-10b5-4123-84d6-2ee4c61a49e7
# $environmentName = "Default-12517306-9857-4dca-b594-6c370d359eb0"