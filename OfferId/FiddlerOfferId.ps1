Login-AzureRmAccount

#insert bearer token below.  DO NOT INCLUDE "BEARER " on the token - it is added for you later.  Just insert the token value.
$billingBearerToken = 'INSERT TOKEN VALUE HERE'

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

$subscriptions = Get-AzureRmSubscription

$subscriptionArray = @()

foreach($subscription in $subscriptions){
$managementTemplateURI = "https://management.azure.com/subscriptions/{0}?api-version=2018-02-01"
$managementURI = $managementTemplateURI -f $subscription.Id

$Headers = @{}
$Headers.Add("Authorization","Bearer " + $tokenValue)
Write-Host "Pulling quotaId for subscription - management.azure.com:" $subscription.Name "-" $subscription.Id -ForegroundColor Green
$SubscriptionData = Invoke-RestMethod -Method Get -Headers $Headers -Uri $managementURI

$billingURI = "https://s2.billing.ext.azure.com/api/Billing/Subscription/Subscription?api-version=2019-01-14"
$billingFormData = @{subscriptionId = $SubscriptionData.subscriptionId
                    subscriptionType = 4
                    quotaId = $SubscriptionData.subscriptionPolicies.quotaId
                    }
$billingFormFinal = $billingFormData | ConvertTo-Json 

$SubscriptionDetails = $null
#include bearer token
$Headers = @{}
$Headers.Add("Authorization","Bearer " + $billingBearerToken)
$SubscriptionDetails = Invoke-RestMethod -Method POST -Headers $Headers -Body $billingFormFinal -ContentType 'application/json' -Uri $billingURI

#got offerId - build out reporting object
$subscriptionObject = New-Object psobject
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionId' -Value $subscription.Id
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $subscription.Name
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionQuotaId' -Value $SubscriptionData.subscriptionPolicies.quotaId
$subscriptionObject | Add-Member -MemberType NoteProperty -Name 'SubscriptionOfferId' -Value $SubscriptionDetails.essentials.offerId

$subscriptionArray += $subscriptionObject
}

$subscriptionArray | Format-Table
$subscriptionArray | select SubscriptionQuotaId, SubscriptionOfferId -Unique | Format-Table
