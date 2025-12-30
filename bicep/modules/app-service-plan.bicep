// =============================================================================
// Module: App Service Plan
// =============================================================================
// Creates an App Service Plan for hosting Web Apps and Function Apps.
//
// Usage:
//   module appServicePlan 'app-service-plan.bicep' = {
//     name: 'app-service-plan'
//     params: {
//       planName: 'myapp-plan-dev'
//       location: location
//       sku: 'B1'
//     }
//   }
// =============================================================================

@description('Name of the App Service Plan')
param planName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU name (F1, B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3, Y1 for Consumption)')
param sku string = 'B1'

@description('Operating system (Windows or Linux)')
@allowed(['Windows', 'Linux'])
param operatingSystem string = 'Windows'

@description('Number of workers')
@minValue(1)
param capacity int = 1

@description('Tags to apply to the resource')
param tags object = {}

// Determine tier from SKU
var skuTier = sku == 'F1' ? 'Free'
  : sku == 'D1' ? 'Shared'
  : startsWith(sku, 'B') ? 'Basic'
  : startsWith(sku, 'S') ? 'Standard'
  : startsWith(sku, 'P1v3') || startsWith(sku, 'P2v3') || startsWith(sku, 'P3v3') ? 'PremiumV3'
  : startsWith(sku, 'P') ? 'PremiumV2'
  : sku == 'Y1' ? 'Dynamic'
  : 'Standard'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: skuTier
    capacity: capacity
  }
  properties: {
    reserved: operatingSystem == 'Linux'
  }
}

// Outputs
@description('Resource ID of the App Service Plan')
output id string = appServicePlan.id

@description('Name of the App Service Plan')
output name string = appServicePlan.name

@description('SKU of the App Service Plan')
output skuName string = appServicePlan.sku.name
