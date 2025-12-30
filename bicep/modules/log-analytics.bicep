// =============================================================================
// Module: Log Analytics Workspace
// =============================================================================
// Creates a Log Analytics workspace for centralized logging and monitoring.
//
// Usage:
//   module logAnalytics 'log-analytics.bicep' = {
//     name: 'log-analytics'
//     params: {
//       workspaceName: 'myapp-log-dev'
//       location: location
//     }
//   }
// =============================================================================

@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU for the workspace')
@allowed(['PerGB2018', 'Free', 'Standalone', 'PerNode'])
param sku string = 'PerGB2018'

@description('Data retention in days (30-730)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tags to apply to the resource')
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
  }
}

// Outputs
@description('Resource ID of the Log Analytics workspace')
output id string = logAnalyticsWorkspace.id

@description('Name of the Log Analytics workspace')
output name string = logAnalyticsWorkspace.name

@description('Workspace ID (customer ID) for agents')
output workspaceId string = logAnalyticsWorkspace.properties.customerId
