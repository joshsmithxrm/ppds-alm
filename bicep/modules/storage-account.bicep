// =============================================================================
// Module: Storage Account
// =============================================================================
// Creates a Storage Account, typically used by Azure Functions.
//
// Usage:
//   module storage 'storage-account.bicep' = {
//     name: 'storage'
//     params: {
//       storageAccountName: 'myappstdev'
//       location: location
//     }
//   }
// =============================================================================

@description('Name of the storage account (3-24 chars, lowercase alphanumeric)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU for the storage account')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_RAGRS', 'Standard_ZRS', 'Premium_LRS'])
param sku string = 'Standard_LRS'

@description('Storage account kind')
@allowed(['StorageV2', 'Storage', 'BlobStorage'])
param kind string = 'StorageV2'

@description('Minimum TLS version')
@allowed(['TLS1_0', 'TLS1_1', 'TLS1_2'])
param minimumTlsVersion string = 'TLS1_2'

@description('Allow public blob access')
param allowBlobPublicAccess bool = false

@description('Tags to apply to the resource')
param tags object = {}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: allowBlobPublicAccess
  }
}

// Outputs
@description('Resource ID of the storage account')
output id string = storageAccount.id

@description('Name of the storage account')
output name string = storageAccount.name

@description('Primary connection string')
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'

@description('Primary blob endpoint')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
