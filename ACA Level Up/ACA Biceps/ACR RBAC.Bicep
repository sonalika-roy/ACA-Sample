param acaIdentityName string
param roleGuid string

resource acaIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: acaIdentityName
}

resource role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, roleGuid)
  properties: {
    principalId: acaIdentity.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGuid) //AcrPull
  }
  dependsOn:[
    acaIdentity
  ]
}
