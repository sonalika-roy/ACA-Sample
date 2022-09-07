
param environment_name string

var logAnalyticsWorkspaceName = 'logs-${environment_name}'
//var appInsightsName = 'appins-${environment_name}'


@description('Location for all resources.')
param location string = resourceGroup().location



resource la 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName 
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}



resource env 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environment_name
  location: location
  properties: {
    // not recognized but type is required
  
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: la.properties.customerId
        sharedKey: la.listKeys().primarySharedKey
      }
    }
    }
  }
