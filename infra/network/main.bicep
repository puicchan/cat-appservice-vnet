targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Resource group name for network resources')
param networkResourceGroupName string = ''

var abbrs = loadJsonContent('../abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName, 'azd-provision-layer': 'network' }

// Organize network resources in a resource group
resource networkRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(networkResourceGroupName) ? networkResourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}-network'
  location: location
  tags: tags
}

// NSG for Container Apps subnet
module nsg './nsg.bicep' = {
  name: 'nsg-deployment'
  scope: networkRg
  params: {
    nsgName: '${abbrs.networkNetworkSecurityGroups}${resourceToken}-container-apps'
    location: location
    tags: tags
  }
}

// Virtual Network with delegated subnet
module vnet './vnet.bicep' = {
  name: 'vnet-deployment'
  scope: networkRg
  params: {
    vnetName: '${abbrs.networkVirtualNetworks}${resourceToken}'
    location: location
    tags: tags
    nsgId: nsg.outputs.nsgId
  }
}

output VNET_ID string = vnet.outputs.vnetId
output VNET_NAME string = vnet.outputs.vnetName
output CONTAINER_APPS_SUBNET_ID string = vnet.outputs.subnetId
output CONTAINER_APPS_SUBNET_NAME string = vnet.outputs.subnetName
output NETWORK_RESOURCE_GROUP_NAME string = networkRg.name
