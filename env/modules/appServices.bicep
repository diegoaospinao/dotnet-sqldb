// Parameters
@description('Location for all resources.')
param location string 

@description('Service plan name that contain application services.')
param appServicePlanName string 

@description('Service plan sku name that contain application services.')
@allowed([
  'F1'
  'B1'
  'P0v3'
])
param appServicePlanSkuName string

@description('Application service name for frontend.')
param appServiceName string

@description('Existing subnet for application gateway.')
param backendSubnetId string

@description('Existing managed identity name.')
param managedIdentityName string

// Variables
var managedIdentityId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities',managedIdentityName)

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
}

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}' : {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: backendSubnetId
    vnetRouteAllEnabled: true
    httpsOnly: true
  }
}

// Outputs
output appServiceName string = appService.name
output appServiceHostName string = appService.properties.defaultHostName
