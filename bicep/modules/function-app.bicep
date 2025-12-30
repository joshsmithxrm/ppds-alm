// =============================================================================
// Module: Function App
// =============================================================================
// Creates an Azure Function App for serverless compute.
//
// Usage:
//   module functionApp 'function-app.bicep' = {
//     name: 'function-app'
//     params: {
//       functionAppName: 'myapp-func-dev'
//       location: location
//       appServicePlanId: appServicePlan.outputs.id
//       storageAccountConnectionString: storage.outputs.connectionString
//       appInsightsConnectionString: appInsights.outputs.connectionString
//     }
//   }
// =============================================================================

@description('Name of the Function App')
param functionAppName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('Storage account connection string')
param storageAccountConnectionString string

@description('Functions runtime')
@allowed(['dotnet', 'dotnet-isolated', 'node', 'python', 'java', 'powershell'])
param runtime string = 'dotnet-isolated'

@description('Functions runtime version')
param runtimeVersion string = '8.0'

@description('Functions extension version')
@allowed(['~4', '~3'])
param functionsExtensionVersion string = '~4'

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
var baseAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: storageAccountConnectionString
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storageAccountConnectionString
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(functionAppName)
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: functionsExtensionVersion
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: runtime
  }
]

var appInsightsSettings = appInsightsConnectionString != '' ? [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: appInsightsConnectionString
  }
] : []

var allAppSettings = concat(baseAppSettings, appInsightsSettings, appSettings)

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  tags: tags
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: {
      netFrameworkVersion: runtime == 'dotnet-isolated' || runtime == 'dotnet' ? 'v${runtimeVersion}' : null
      appSettings: allAppSettings
    }
  }
}

// Outputs
@description('Resource ID of the Function App')
output id string = functionApp.id

@description('Name of the Function App')
output name string = functionApp.name

@description('Default hostname of the Function App')
output defaultHostName string = functionApp.properties.defaultHostName

@description('URL of the Function App')
output url string = 'https://${functionApp.properties.defaultHostName}'

@description('Principal ID of the managed identity (empty if disabled)')
output principalId string = enableManagedIdentity ? functionApp.identity.principalId : ''
