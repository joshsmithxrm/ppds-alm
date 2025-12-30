// =============================================================================
// Module: Application Insights
// =============================================================================
// Creates an Application Insights resource for application monitoring.
//
// Usage:
//   module appInsights 'application-insights.bicep' = {
//     name: 'app-insights'
//     params: {
//       appInsightsName: 'myapp-ai-dev'
//       location: location
//       logAnalyticsWorkspaceId: logAnalytics.outputs.id
//     }
//   }
// =============================================================================

@description('Name of the Application Insights resource')
param appInsightsName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('Application type')
@allowed(['web', 'other'])
param applicationType string = 'web'

@description('Tags to apply to the resource')
param tags object = {}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: applicationType
  tags: tags
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

// Outputs
@description('Resource ID of the Application Insights resource')
output id string = appInsights.id

@description('Name of the Application Insights resource')
output name string = appInsights.name

@description('Connection string for Application Insights')
output connectionString string = appInsights.properties.ConnectionString

@description('Instrumentation key (legacy, prefer connection string)')
output instrumentationKey string = appInsights.properties.InstrumentationKey
