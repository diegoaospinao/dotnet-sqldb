// Parameters
@description('Location for all resources.')
param location string

@description('Location for all resources.')
param locationReplica string

@description('SQL logical server name.')
param sqlServerName string 

@description('SQL logical server name.')
param sqlServerReplicaName string 

@description('SQL logical server administrator username.')
@secure()
param sqlServerAdminUser string

@description('SQL logical server administrator password.')
@secure()
param sqlServerAdminPassword string

@description('SQL database name.')
param sqlDataBaseName string

@description('SQL database sku name.')
@allowed([
  'Free'
  'Basic'
  'S0'
  'P1'
])
param sqlDataBaseSkuName string

@description('Private endpoint name')
param privateSqlEndpointName string

@description('Private sql dns zone name')
param privateSqlDnsZoneName string

@description('Existing subnet for application gateway.')
param dataSubnetId string

@description('Existing subnet for application gateway.')
param virtualNetworkId string

// Variables


resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdminUser
    administratorLoginPassword: sqlServerAdminPassword
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlServerReplica 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerReplicaName
  location: locationReplica
  properties: {
    administratorLogin: sqlServerAdminUser
    administratorLoginPassword: sqlServerAdminPassword
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlDataBase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: sqlDataBaseName
  location: location
  sku: {
    name: sqlDataBaseSkuName
  }
}

resource sqlDataBaseReplica 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServerReplica
  name: sqlDataBaseName
  location: locationReplica
  sku: {
    name: sqlDataBaseSkuName
  }
  properties:{
    createMode: 'Secondary'
    sourceDatabaseId: sqlDataBase.id
  }
}

resource privateSqlEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateSqlEndpointName
  location: location
  properties: {
    subnet: {
      id: dataSubnetId
    }
    customNetworkInterfaceName: '${privateSqlEndpointName}-nic'
    privateLinkServiceConnections: [
      {
        name: privateSqlEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
      {
        name: '${privateSqlEndpointName}-replica'
        properties: {
          privateLinkServiceId: sqlServerReplica.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource privateSqlDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' =  {
  name: privateSqlDnsZoneName
  location: 'global'
  properties: {}
}

resource privateSqlDnsZoneLink  'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateSqlDnsZone
  name: '${privateSqlDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateSqlDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: privateSqlEndpoint
  name: 'default'  
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'default'
        properties: {
          privateDnsZoneId: privateSqlDnsZone.id
        }
      }
    ]
  }
}


// Outputs
output serverFQDN string = sqlServer.properties.fullyQualifiedDomainName
