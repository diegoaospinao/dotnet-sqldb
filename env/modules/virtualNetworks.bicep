// Parameters
@description('Location for all resources.')
param location string

@description('Virtual network name related to application gateway.')
param virtualNetworkName string 

// Variables
var appGatewaySubnetName = 'agsubnet'
var backendSubnetName = 'backendsubnet'
var dataSubnetName = 'datasubnet'
var storageSubnetName = 'storagesubnet'

resource vNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: backendSubnetName
        properties: {
          addressPrefix: '10.1.1.0/24'
          delegations: [
            {
              name: 'delegation'             
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
        }
      }
      {
        name: dataSubnetName
        properties: {
          addressPrefix: '10.1.2.0/24'
        }
      }
      {
        name: storageSubnetName
        properties: {
          addressPrefix: '10.1.3.0/24'
        }
      }
    ] 
  }

  resource appGatewaySubnet 'subnets' existing = {
    name: appGatewaySubnetName
  }

  resource backendSubnet 'subnets' existing = {
    name: backendSubnetName
  }

  resource dataSubnet 'subnets' existing = {
    name: dataSubnetName
  }

  resource storageSubnet 'subnets' existing = {
    name: storageSubnetName
  }
}

// Outputs
output virtualNetworkId string = vNet.id
output virtualNetworkName string = vNet.name
output appGatewaySubnetId string =  vNet::appGatewaySubnet.id
output appGatewaySubnetName string = vNet::appGatewaySubnet.name
output backendSubnetId string = vNet::backendSubnet.id
output backendSubnetName string = vNet::backendSubnet.name
output dataSubnetId string = vNet::dataSubnet.id
output dataSubnetName string = vNet::dataSubnet.name
output storageSubnetId string = vNet::storageSubnet.id
output storageSubnetName string = vNet::storageSubnet.name
