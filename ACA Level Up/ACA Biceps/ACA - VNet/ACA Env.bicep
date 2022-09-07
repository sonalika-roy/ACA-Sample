param environment_name string
param location string = 'eastus'

var logAnalyticsWorkspaceName = 'logs-${environment_name}'
var appInsightsName = 'appins-${environment_name}'
var kvname = 'kvaca-${environment_name}'

resource logAnalyticsWorkspace'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'myacavnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource infrasubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: virtualNetwork
  name: 'infraSubnetName'
  properties: {
    addressPrefix: '10.0.0.0/21'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource servicepe 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' = {
  parent: virtualNetwork
  name: 'servicespe'
  properties: {
    addressPrefix: '10.0.10.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}



resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: 'sracracatest'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
  }
}



resource acrprivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'acrprivateEndpoint'
  location: location
  properties: {
    subnet: {
      id: servicepe.id
    }
    privateLinkServiceConnections: [
      {
        name: 'acrprivateEndpoint'
        properties: {
          privateLinkServiceId: acrResource.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource acrprivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
}

resource acrprivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: acrprivateDnsZone
  name: 'acrprivateDnsZone-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}


resource kvResource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvname
  location: location
  properties: {
    accessPolicies: [
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: '72f988bf-86f1-41af-91ab-2d7cd011db47'
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource kvprivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'kvprivateEndpoint'
  location: location
  properties: {
    subnet: {
      id: servicepe.id
    }
    privateLinkServiceConnections: [
      {
        name: 'kvprivateEndpoint'
        properties: {
          privateLinkServiceId: kvResource.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource kvprivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
}

resource kvprivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: kvprivateDnsZone
  name: 'kvprivateDnsZone-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}


resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environment_name
  location: location
  
  properties: {
       appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspace.id, '2021-06-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, '2021-06-01').primarySharedKey
      }
      
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: infrasubnet.id
      dockerBridgeCidr: '10.2.0.1/16'
      platformReservedCidr: '10.1.0.0/16'
      platformReservedDnsIP: '10.1.0.2'
     // runtimeSubnetId: runtimesubnet.id
    }
    zoneRedundant: true
  }
  
}
