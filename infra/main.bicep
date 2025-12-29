targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param containerAppEnvironmentName string = ''
param containerRegistryName string = ''
param resourceGroupName string = ''
param webServiceName string = ''
param webExists bool = false
// serviceName is used as value for the tag (azd-service-name) azd uses to identify
param serviceName string = 'web'

// Network parameters from layered provision
param containerAppsSubnetId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Monitor application with Azure Monitor
module monitoring 'br/public:avm/ptn/azd/monitoring:0.1.0' = {
  name: 'monitoring'
  scope: rg
  params: {
    logAnalyticsName: 'log-${resourceToken}'
    applicationInsightsName: 'appi-${resourceToken}'
    applicationInsightsDashboardName: 'appid-${resourceToken}'
    location: location
    tags: tags
  }
}

// Container Registry
module containerRegistry 'br/public:avm/res/container-registry/registry:0.6.0' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    acrSku: 'Basic'
    acrAdminUserEnabled: true
    tags: tags
  }
}

// Container Apps Environment with VNET
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.8.1' = {
  name: 'container-apps-environment'
  scope: rg
  params: {
    name: !empty(containerAppEnvironmentName) ? containerAppEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    location: location
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    zoneRedundant: false
    infrastructureSubnetId: !empty(containerAppsSubnetId) ? containerAppsSubnetId : null
    internal: false
    workloadProfiles: !empty(containerAppsSubnetId) ? [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ] : []
    tags: tags
  }
}

// Managed identity for web frontend
module webIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'webidentity'
  scope: rg
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}web-${resourceToken}'
    location: location
  }
}

// The application frontend
// Using AVM container-app-upsert for azd image-based deployment
module web 'br/public:avm/ptn/azd/container-app-upsert:0.1.2' = {
  name: serviceName
  scope: rg
  params: {
    name: !empty(webServiceName) ? webServiceName : '${abbrs.appContainerApps}web-${resourceToken}'
    tags: union(tags, { 'azd-service-name': serviceName })
    location: location
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
    containerRegistryName: containerRegistry.outputs.name
    exists: webExists
    containerName: 'main'
    identityType: 'UserAssigned'
    identityName: webIdentity.outputs.name
    userAssignedIdentityResourceId: webIdentity.outputs.resourceId
    identityPrincipalId: webIdentity.outputs.principalId
    containerCpuCoreCount: '0.5'
    containerMemory: '1Gi'
    targetPort: 80
    ingressEnabled: true
    containerMinReplicas: 1
    external: true
  }
}

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerAppsEnvironment.outputs.name
output REACT_APP_WEB_BASE_URL string = web.outputs.uri
output SERVICE_WEB_NAME string = web.outputs.name
