@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the Queue')
param serviceBusQueueName string

@description('Location for all resources.')
param location string = resourceGroup().location
param name string
param useExternalIngress bool
param containerPort int
param acaIdentityName string 
//param envVars array = []
param envname string
param acrName string //User to provide each time
//param containerImage string = 'acalevelupdemoacr.azurecr.io/samples/blue5:latest' //User to provide each time
//param containerImage string //User to provide each time

param containerImage string = 'acalevelupdemoacr.azurecr.io/samples/green:latest' //User to provide each time


resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}
/*
resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' existing = {
  parent: serviceBusNamespace
  name: serviceBusQueueName
}
*/

resource sbaccess 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: serviceBusNamespace
  
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: envname
}




  resource acaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
    name: acaIdentityName
  }




  resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
    name: name
    location: location    
    identity: {
        type: 'SystemAssigned,UserAssigned'
        userAssignedIdentities: {
            '${acaIdentity.id}': {}
        }
    }
    properties: {
        managedEnvironmentId: containerAppEnvironment.id
        configuration: {
            activeRevisionsMode: 'Multiple'
            secrets: [
                  {
                    name: 'servicebusconnectionstring'
                    value: sbaccess.listKeys().primaryConnectionString
                  }
                
            ]
            
            registries: [
                {
                    server: '${acrName}.azurecr.io'
                    //username: acrName
                    //passwordSecretRef: 'acrtokenpwd'
                    identity: acaIdentity.id
                }
            ]
            ingress: {
              traffic: [
                {
                  revisionName: 'acalevelupapp2--m59eu5v'
                  weight: 50
                }
                {
                  revisionName: 'acalevelupapp2--12hvw23'
                  weight: 50
                }
              ]
                external: useExternalIngress
                targetPort: containerPort
            }
        }
        template: {
            containers: [
                {
                    image: containerImage
                    name: 'acasrtest'
                    env: [
                      {
                          name: 'serviceBusQueueName'
                          value: serviceBusQueueName
                      }
                      {
                          name: 'ConnectionString'
                          secretRef: 'servicebusconnectionstring'
                      }
                  ]
                   command: [
                  ]
                }
            ]
            scale: {
                minReplicas: 1
                maxReplicas: 30
                rules: [
                 {
                   name: 'queue-based-autoscaling'
                   custom: {
                     type: 'azure-servicebus'
                     metadata: {
                      queueName: serviceBusQueueName
                      messageCount: '20'
              }
                   auth: [{
                     secretRef: 'servicebusconnectionstring'
                     triggerParameter: 'connection'
              }]
        }
    }]
            }
        }
    }
}
