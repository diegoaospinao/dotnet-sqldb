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

// Variables

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
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

// Outputs
output appServiceName string = appService.name
output appServiceHostName string = appService.properties.defaultHostName
