// Parameters
@description('Location for all resources.')
param location string

@description('Azure storage account name.')
param storageAccountName string 

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

@description('File share name. File share names must be between 3 and 63 characters in length and use numbers, lower-case letters and dash (-) only.')
param fileShareName string

@description('Private endpoint name')
param privateBlobEndpointName string

@description('Private sql dns zone name')
param privateBlobDnsZoneName string

@description('Existing subnet for application gateway.')
param storageSubnetId string

@description('Existing subnet for application gateway.')
param virtualNetworkId string

@description('Existing managed identity name.')
param managedIdentityName string

// Variables
var managedIdentityId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities',managedIdentityName)
var roleDefinitionId = resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountSkuName
  }
  properties: {
    accessTier: 'Hot'
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/${fileShareName}'
}

resource privateBlobEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateBlobEndpointName
  location: location
  properties: {
    subnet: {
      id: storageSubnetId
    }
    customNetworkInterfaceName: '${privateBlobEndpointName}-nic'
    privateLinkServiceConnections: [
      {
        name: privateBlobEndpointName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateBlobDnsZoneName
  location: 'global'
  properties: {}
}

resource privateBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateBlobDnsZone
  name: '${privateBlobDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: privateBlobEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateBlobDnsZone.id
        }
      }
    ]
  }
}

// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   scope: storageAccount
//   name: guid(storageAccount.id, managedIdentityId, roleDefinitionId)
//   properties: {
//     roleDefinitionId: roleDefinitionId
//     principalId: managedIdentityId
//     principalType: 'ServicePrincipal'
//   }
// }

// Outputs
output id string = storageAccount.id
