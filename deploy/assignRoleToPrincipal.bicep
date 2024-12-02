param principalId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: 'intrinsicweb'
}

// Role Assignment: Grant AcrPull to Web App Managed Identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Generate a unique GUID for the role assignment
  name: guid(principalId, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role definition ID
    // Use the Web App's Managed Identity
    principalId: principalId
  }
}
