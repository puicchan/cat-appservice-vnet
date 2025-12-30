param name string
param location string = resourceGroup().location
param tags object = {}
param serviceName string = 'web'
param appCommandLine string = 'gunicorn --bind=0.0.0.0:8000 --timeout 600 --access-logfile "-" --error-logfile "-" app:app'
param appInsightResourceId string
param appServicePlanId string
param linuxFxVersion string = 'python|3.10'
param kind string = 'app,linux'
param virtualNetworkSubnetId string = ''

module web 'br/public:avm/res/web/site:0.19.4' = {
  name: '${name}-deployment'
  params: {
    kind: kind
    name: name
    serverFarmResourceId: appServicePlanId
    tags: union(tags, { 'azd-service-name': serviceName })
    location: location
    virtualNetworkSubnetResourceId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : null
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      appCommandLine: appCommandLine
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
    }
    configs: [
      {
        name: 'logs'
        properties: {
          applicationLogs: { fileSystem: { level: 'Verbose' } }
          detailedErrorMessages: { enabled: true }
          failedRequestsTracing: { enabled: true }
          httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
        }
      }
      {
        name: 'appsettings'
        properties: {
          ApplicationInsightsAgent_EXTENSION_VERSION: contains(kind, 'linux') ? '~3' : '~2'
          APPLICATIONINSIGHTS_CONNECTION_STRING: reference(appInsightResourceId, '2020-02-02-preview').ConnectionString
          ENABLE_ORYX_BUILD: 'true'
          SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
        }
      }
    ]
  }
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.?systemAssignedMIPrincipalId ?? ''
output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = 'https://${web.outputs.defaultHostname}'
