// =============================================================================
// Module: Dataverse Integration (Composite)
// =============================================================================
// Deploys a complete Azure infrastructure for Dataverse integration:
//   - Log Analytics + Application Insights (observability)
//   - Storage Account (Function App storage)
//   - App Service Plan (shared hosting)
//   - App Service (Web API)
//   - Function App (webhook/trigger handlers)
//   - Service Bus (async messaging)
//
// Usage:
//   module integration 'dataverse-integration.bicep' = {
//     name: 'dataverse-integration'
//     params: {
//       appNamePrefix: 'myapp'
//       environment: 'dev'
//       serviceBusQueues: [
//         { name: 'account-updates' }
//       ]
//     }
//   }
// =============================================================================

targetScope = 'resourceGroup'

// Required parameters
@description('Application name prefix used for all resources')
param appNamePrefix string

@description('Environment name (dev, qa, prod)')
@allowed(['dev', 'qa', 'prod'])
param environment string

// Optional parameters
@description('Location for all resources')
param location string = resourceGroup().location

@description('App Service Plan SKU (defaults based on environment)')
param appServicePlanSku string = ''

@description('Service Bus SKU (defaults based on environment)')
param serviceBusSku string = ''

@description('Service Bus queues to create')
param serviceBusQueues array = []

@description('.NET Framework version for web apps')
@allowed(['v6.0', 'v7.0', 'v8.0'])
param netFrameworkVersion string = 'v8.0'

@description('Functions runtime')
@allowed(['dotnet', 'dotnet-isolated', 'node', 'python', 'java', 'powershell'])
param functionsRuntime string = 'dotnet-isolated'

@description('Additional app settings for Web API')
param webApiAppSettings array = []

@description('Additional app settings for Function App')
param functionAppSettings array = []

@description('Tags to apply to all resources')
param tags object = {}

// Computed values
var uniqueSuffix = uniqueString(resourceGroup().id)
var effectiveAppServicePlanSku = appServicePlanSku != '' ? appServicePlanSku : (environment == 'prod' ? 'P1v3' : 'B1')
var effectiveServiceBusSku = serviceBusSku != '' ? serviceBusSku : (environment == 'prod' ? 'Standard' : 'Basic')

// Resource names
var logAnalyticsName = '${appNamePrefix}-log-${environment}'
var appInsightsName = '${appNamePrefix}-ai-${environment}'
var storageAccountName = take(replace('${appNamePrefix}st${environment}${uniqueSuffix}', '-', ''), 24)
var appServicePlanName = '${appNamePrefix}-plan-${environment}'
var webAppName = '${appNamePrefix}-api-${environment}-${uniqueSuffix}'
var functionAppName = '${appNamePrefix}-func-${environment}-${uniqueSuffix}'
var serviceBusNamespaceName = '${appNamePrefix}-sb-${environment}-${uniqueSuffix}'

// Merged tags
var allTags = union(tags, {
  environment: environment
  application: appNamePrefix
  managedBy: 'ppds-alm'
})

// =============================================================================
// Module Deployments
// =============================================================================

// Log Analytics Workspace
module logAnalytics 'log-analytics.bicep' = {
  name: 'logAnalytics-${environment}'
  params: {
    workspaceName: logAnalyticsName
    location: location
    tags: allTags
  }
}

// Application Insights
module appInsights 'application-insights.bicep' = {
  name: 'appInsights-${environment}'
  params: {
    appInsightsName: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: allTags
  }
}

// Storage Account
module storage 'storage-account.bicep' = {
  name: 'storage-${environment}'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: allTags
  }
}

// App Service Plan (shared)
module appServicePlan 'app-service-plan.bicep' = {
  name: 'appServicePlan-${environment}'
  params: {
    planName: appServicePlanName
    location: location
    sku: effectiveAppServicePlanSku
    tags: allTags
  }
}

// Web API App Service
module webApp 'app-service.bicep' = {
  name: 'webApp-${environment}'
  params: {
    appName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    netFrameworkVersion: netFrameworkVersion
    appInsightsConnectionString: appInsights.outputs.connectionString
    appSettings: webApiAppSettings
    tags: allTags
  }
}

// Function App
module functionApp 'function-app.bicep' = {
  name: 'functionApp-${environment}'
  params: {
    functionAppName: functionAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    storageAccountConnectionString: storage.outputs.connectionString
    runtime: functionsRuntime
    appInsightsConnectionString: appInsights.outputs.connectionString
    appSettings: concat([
      {
        name: 'WebApiBaseUrl'
        value: webApp.outputs.url
      }
      {
        name: 'ServiceBusConnection'
        value: serviceBus.outputs.connectionString
      }
    ], functionAppSettings)
    tags: allTags
  }
}

// Service Bus
module serviceBus 'service-bus.bicep' = {
  name: 'serviceBus-${environment}'
  params: {
    namespaceName: serviceBusNamespaceName
    location: location
    sku: effectiveServiceBusSku
    queues: serviceBusQueues
    tags: allTags
  }
}

// =============================================================================
// Outputs
// =============================================================================

// Web API
@description('Web API App Service name')
output webAppName string = webApp.outputs.name

@description('Web API URL')
output webAppUrl string = webApp.outputs.url

@description('Web API managed identity principal ID')
output webAppPrincipalId string = webApp.outputs.principalId

// Function App
@description('Function App name')
output functionAppName string = functionApp.outputs.name

@description('Function App URL')
output functionAppUrl string = functionApp.outputs.url

@description('Function App managed identity principal ID')
output functionAppPrincipalId string = functionApp.outputs.principalId

// Service Bus
@description('Service Bus namespace name')
output serviceBusNamespace string = serviceBus.outputs.name

@description('Service Bus connection string')
output serviceBusConnectionString string = serviceBus.outputs.connectionString

// Observability
@description('Application Insights name')
output appInsightsName string = appInsights.outputs.name

@description('Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('Log Analytics workspace name')
output logAnalyticsName string = logAnalytics.outputs.name

// Storage
@description('Storage account name')
output storageAccountName string = storage.outputs.name
