param vnetName string
param location string
param tags object
param nsgId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: 'container-apps-subnet'
  properties: {
    addressPrefix: '10.0.0.0/23'
    networkSecurityGroup: {
      id: nsgId
    }
    delegations: [
      {
        name: 'delegation-to-container-apps'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetId string = subnet.id
output subnetName string = subnet.name
