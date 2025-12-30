// =============================================================================
// Module: Service Bus
// =============================================================================
// Creates an Azure Service Bus namespace with optional queues.
//
// Security: This module creates a scoped authorization rule with Send and Listen
// permissions only (principle of least privilege). The RootManageSharedAccessKey
// is not exposed. If you need Manage permissions, retrieve them from Azure portal.
//
// Usage:
//   module serviceBus 'service-bus.bicep' = {
//     name: 'service-bus'
//     params: {
//       namespaceName: 'myapp-sb-dev'
//       location: location
//       queues: [
//         { name: 'account-updates' }
//         { name: 'notifications', maxDeliveryCount: 5 }
//       ]
//     }
//   }
// =============================================================================

@description('Name of the Service Bus namespace')
param namespaceName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU tier')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Queue configurations to create')
param queues array = []
// Queue object schema:
// {
//   name: string (required)
//   maxDeliveryCount: int (optional, default: 10)
//   lockDuration: string (optional, default: 'PT5M')
//   defaultMessageTimeToLive: string (optional, default: 'P14D')
// }

@description('Tags to apply to the resource')
param tags object = {}

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
}

// Service Bus Queues
resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = [for queue in queues: {
  parent: serviceBusNamespace
  name: queue.name
  properties: {
    maxDeliveryCount: contains(queue, 'maxDeliveryCount') ? queue.maxDeliveryCount : 10
    lockDuration: contains(queue, 'lockDuration') ? queue.lockDuration : 'PT5M'
    defaultMessageTimeToLive: contains(queue, 'defaultMessageTimeToLive') ? queue.defaultMessageTimeToLive : 'P14D'
  }
}]

// Application access policy (least privilege - Send and Listen only)
// This follows the principle of least privilege. Applications typically only need
// to send and receive messages, not manage the namespace. If you need Manage
// permissions, use RootManageSharedAccessKey from the Azure portal.
resource appAccessPolicy 'Microsoft.ServiceBus/namespaces/authorizationRules@2021-11-01' = {
  name: 'app-access'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
}

// Outputs
@description('Resource ID of the Service Bus namespace')
output id string = serviceBusNamespace.id

@description('Name of the Service Bus namespace')
output name string = serviceBusNamespace.name

@description('Connection string with Send and Listen permissions (least privilege)')
output connectionString string = listKeys(appAccessPolicy.id, serviceBusNamespace.apiVersion).primaryConnectionString

@description('Endpoint URL of the Service Bus namespace')
output endpoint string = serviceBusNamespace.properties.serviceBusEndpoint
