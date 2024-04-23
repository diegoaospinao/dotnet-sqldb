// Parameters

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Prefix name')
param prefix string

@description('Suffix name')
param suffix string = substring('${uniqueString(resourceGroup().id)}',0,6)

@description('Environment for all resources.')
@allowed([
  'test'
  'staging'
  'prod'
])
param environment string

@description('Existing managed identity name.')
param managedIdentityName string

@description('SQL logical server administrator username.')
@secure()
param sqlServerAdminUser string

@description('SQL logical server administrator password.')
@secure()
param sqlServerAdminPassword string

@description('SQL database sku name.')
@allowed([
  'Free'
  'Basic'
  'S0'
  'P1'
])
param sqlDataBaseSkuName string

@description('Azure storage account sku name.')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountSkuName string

@description('Service plan sku name that contain application services.')
@allowed([
  'F1'
  'B1'
  'P0v3'
])
param appServicePlanSkuName string

@description('Private sql endpoint name')
param privateSqlEndpointName string = 'pe-${prefix}-sql-${environment}-${suffix}'

@description('Private blob endpoint name')
param privateBlobEndpointName string = 'pe-${prefix}-blob-${environment}-${suffix}'

@description('Virtual network name related to application gateway.')
param virtualNetworkName string = 'vnet-${prefix}-${environment}-${suffix}'

@description('SQL logical server name.')
param sqlServerName string = 'sql-${prefix}-${environment}-${suffix}'

@description('SQL database name.')
param sqlDataBaseName string = 'sqldb-${prefix}-${environment}'

@description('Azure storage account name.')
param storageAccountName string = 'st${prefix}${environment}${suffix}'

@description('File share name. File share names must be between 3 and 63 characters in length and use numbers, lower-case letters and dash (-) only.')
param fileShareName string = 'files'

@description('Service plan name that contain application services.')
param appServicePlanName string = 'asp-${prefix}-${environment}-${suffix}'

@description('Application service name for backend.')
param appServiceName string = 'app-${prefix}-backend-${environment}-${suffix}'

@description('Privale link database name')
param privateSqlDnsZoneName string = 'privatelink.database.windows.net'

@description('Privale link storage account name')
param privateBlobDnsZoneName string = 'privatelink.blob.core.windows.net'

// Modules

module virtualNetworks 'modules/virtualNetworks.bicep' = {
  name: 'virtualNetworks'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
  }
}

module sqlDatabases 'modules/sqlDatabases.bicep' = {
  name: 'sqlDatabases'
  params: {
    location: location
    sqlDataBaseName: sqlDataBaseName
    sqlDataBaseSkuName: sqlDataBaseSkuName
    sqlServerAdminPassword: sqlServerAdminPassword
    sqlServerAdminUser: sqlServerAdminUser
    sqlServerName: sqlServerName
    privateSqlEndpointName: privateSqlEndpointName
    privateSqlDnsZoneName: privateSqlDnsZoneName
    virtualNetworkId: virtualNetworks.outputs.virtualNetworkId
    dataSubnetId: virtualNetworks.outputs.dataSubnetId
  }
  dependsOn: [virtualNetworks]
}

module storageAccounts 'modules/storageAccounts.bicep' = {
  name: 'storageAccounts'
  params: {
    fileShareName: fileShareName
    location: location
    storageAccountName: storageAccountName 
    storageAccountSkuName: storageAccountSkuName
    privateBlobEndpointName:privateBlobEndpointName
    privateBlobDnsZoneName: privateBlobDnsZoneName
    virtualNetworkId: virtualNetworks.outputs.virtualNetworkId
    storageSubnetId: virtualNetworks.outputs.storageSubnetId
    managedIdentityName: managedIdentityName
  }
  dependsOn: [virtualNetworks]
}

module appServices 'modules/appServices.bicep' = {
  name: 'appServices'
  params: {
    appServiceName: appServiceName
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
    location: location
    backendSubnetId: virtualNetworks.outputs.backendSubnetId
    managedIdentityName: managedIdentityName
  }
}
