// =============================================================================
// Module: App Service (Web App)
// =============================================================================
// Creates an App Service for hosting Web APIs and web applications.
//
// Usage:
//   module webApp 'app-service.bicep' = {
//     name: 'web-app'
//     params: {
//       appName: 'myapp-api-dev'
//       location: location
//       appServicePlanId: appServicePlan.outputs.id
//       appInsightsConnectionString: appInsights.outputs.connectionString
//     }
//   }
// =============================================================================

@description('Name of the App Service')
param appName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('.NET Framework version')
@allowed(['v6.0', 'v7.0', 'v8.0'])
param netFrameworkVersion string = 'v8.0'

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Enable managed identity')
param enableManagedIdentity bool = true

@description('Additional app settings')
param appSettings array = []

@description('Enable HTTPS only')
param httpsOnly bool = true

@description('Tags to apply to the resource')
param tags object = {}

// Build app settings array
var baseAppSettings = appInsightsConnectionString != '' ? [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3'
  }
] : []

var allAppSettings = concat(baseAppSettings, appSettings)

// App Service
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  tags: tags
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: {
      netFrameworkVersion: netFrameworkVersion
      appSettings: allAppSettings
    }
  }
}

// Outputs
@description('Resource ID of the App Service')
output id string = webApp.id

@description('Name of the App Service')
output name string = webApp.name

@description('Default hostname of the App Service')
output defaultHostName string = webApp.properties.defaultHostName

@description('URL of the App Service')
output url string = 'https://${webApp.properties.defaultHostName}'

@description('Principal ID of the managed identity (empty if disabled)')
output principalId string = enableManagedIdentity ? webApp.identity.principalId : ''
