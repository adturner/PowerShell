Login-AzureRmAccount

function Get-AzureRmCachedAccessToken()
{
  $ErrorActionPreference = 'Stop'
  
  if(-not (Get-Module AzureRm.Profile)) {
    Import-Module AzureRm.Profile
  }
  $azureRmProfileModuleVersion = (Get-Module AzureRm.Profile).Version
  # refactoring performed in AzureRm.Profile v3.0 or later
  if($azureRmProfileModuleVersion.Major -ge 3) {
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if(-not $azureRmProfile.Accounts.Count) {
      Write-Error "Ensure you have logged in before calling this function."    
    }
  } else {
    # AzureRm.Profile < v3.0
    $azureRmProfile = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile
    if(-not $azureRmProfile.Context.Account.Count) {
      Write-Error "Ensure you have logged in before calling this function."    
    }
  }
    
  $currentAzureContext = Get-AzureRmContext
  $profileClient = New-Object Microsoft.Azure.Commands.ResoLogin-AzureRmAccount

function Get-AzureRmCachedAccessToken()
{
  $ErrorActionPreference = 'Stop'
  
  if(-not (Get-Module AzureRm.Profile)) {
    Import-Module AzureRm.Profile
  }
  $azureRmProfileModuleVersion = (Get-Module AzureRm.Profile).Version
  # refactoring performed in AzureRm.Profile v3.0 or later
  if($azureRmProfileModuleVersion.Major -ge 3) {
    $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    if(-not $azureRmProfile.Accounts.Count) {
      Write-Error "Ensure you have logged in before calling this function."    
    }
  } else {
    # AzureRm.Profile < v3.0
    $azureRmProfile = [Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile
    if(-not $azureRmProfile.Context.Account.Count) {
      Write-Error "Ensure you have logged in before calling this function."    
    }
  }
    
  $currentAzureContext = Get-AzureRmContext
  $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
  Write-Debug ("Getting access token for tenant" + $currentAzureContext.Subscription.TenantId)
  $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
  return $token.AccessToken  
}

$tokenValue = Get-AzureRmCachedAccessToken

$subscriptions = Get-AzureRmSubscription | Select-Object -first 10

$subscriptionArray = @()

foreach($subscription in $subscriptions){
$managementTemplateURI = "https://management.azure.com/subscriptions/{0}?api-version=2018-02-01" 
$consumptionTemplateURI = "https://management.azure.com/subscriptions/{0}/providers/Microsoft.Consumption/usageDetails?$top=1&api-version=2019-01-01"
$managementURI = $managementTemplateURI -f $subscription.Id
$consumptionURI = $consumptionTemplateURI -f $subscription.Id

$Headers = @{}
$Headers.Add("Authorization","Bearer " + $tokenValue)
Write-Host "Pulling quotaId for subscription - management.azure.com:" $subscription.Name "-" $subscription.Id -ForegroundColor Green
$SubscriptionData = Invoke-RestMethod -Method Get -Headers $Headers -Uri $managementURI

$Headers = @{}
$Headers.Add("Authorization","Bearer " + $tokenValue)
Write-Host "Pulling Offer ID for subscription - management.azure.com:" $subscription.Name "-" $subscription.Id -ForegroundColor Green
$ConsumptionData = Invoke-RestMethod -Method Get -Headers $Headers -Uri $consumptionURI


#got quotaId - build out reporting object
$subscriptionObject = New-Object psobject
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionId' -Value $subscription.Id
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $subscription.Name
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionQuotaId' -Value $SubscriptionData.subscriptionPolicies.quotaId
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionOfferId' -Value $ConsumptionData.value[0].properties.offerId

#you may need to modify this area based on your unique mappings for 
$computedOfferId = 'unknown'
if($SubscriptionData.subscriptionPolicies.quotaId -eq 'EnterpriseAgreement_2014-09-01'){
    $computedOfferId = 'MS-AZR-0017P'
} elseif ($SubscriptionData.subscriptionPolicies.quotaId -eq 'MSDNDevTest_2014-09-01'){
    $computedOfferId = 'MS-AZR-0148P'
}
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionOfferId-Computed' -Value $computedOfferId

$subscriptionArray += $subscriptionObject
}

$subscriptionArray | Format-TableurceManager.Common.RMProfileClient($azureRmProfile)
  Write-Debug ("Getting access token for tenant" + $currentAzureContext.Subscription.TenantId)
  $token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
  return $token.AccessToken  
}

$tokenValue = Get-AzureRmCachedAccessToken

$subscriptions = Get-AzureRmSubscription

$subscriptionArray = @()

foreach($subscription in $subscriptions){
$managementTemplateURI = "https://management.azure.com/subscriptions/{0}?api-version=2018-02-01"
$managementURI = $managementTemplateURI -f $subscription.Id

$Headers = @{}
$Headers.Add("Authorization","Bearer " + $tokenValue)
Write-Host "Pulling quotaId for subscription - management.azure.com:" $subscription.Name "-" $subscription.Id -ForegroundColor Green
$SubscriptionData = Invoke-RestMethod -Method Get -Headers $Headers -Uri $managementURI

#got quotaId - build out reporting object
$subscriptionObject = New-Object psobject
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionId' -Value $subscription.Id
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $subscription.Name
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionQuotaId' -Value $SubscriptionData.subscriptionPolicies.quotaId

#you may need to modify this area based on your unique mappings for 
$computedOfferId = 'unknown'
if($SubscriptionData.subscriptionPolicies.quotaId -eq 'EnterpriseAgreement_2014-09-01'){
    $computedOfferId = 'MS-AZR-0017P'
} elseif ($SubscriptionData.subscriptionPolicies.quotaId -eq 'MSDNDevTest_2014-09-01'){
    $computedOfferId = 'MS-AZR-0148P'
}
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionOfferId' -Value $computedOfferId

$subscriptionArray += $subscriptionObject
}

$subscriptionArray | Format-Table
