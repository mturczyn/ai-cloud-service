@description('Main App Service Plan.')
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'ai-prod-asp'
  location: resourceGroup().location
  sku: {
    name: 'P3v3'
    tier: 'PremiumV3'
    capacity: 1
  }
  properties: {
    // Ensuring that this is a Linux-based App Service Plan
    reserved: true
  }
}

@description('Main Web App resource.')
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'ai-prod-webapp'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'sitecontainers'
    }
  }
}

@description('Main NGINX container.')
resource nginxContainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: webApp
  name: 'nginx'
  properties: {
    image: 'intrinsicweb.azurecr.io/intrinsicweb/configured-nginx:latest'
    isMain: true
    targetPort: '80'
    authType: 'SystemIdentity'
    // environmentVariables: [
    //   {
    //     name: 'NGINX_ENV_VAR'
    //     value: 'example-value' // Replace with required environment variables for NGINX
    //   }
    // ]
  }
}

@description('Sidecar container for Ollama.')
resource ollamaContainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: webApp
  name: 'ollama'
  properties: {
    image: 'ollama/ollama:latest'
    isMain: false
    // environmentVariables: [
    //   {
    //     name: 'OLLAMA_ENV_VAR'
    //     value: 'example-value' // Replace with any required environment variables
    //   }
    // ]
  }
}

module roleAssignment 'assignRoleToPrincipal.bicep' = {
  name: 'assign-acrpull-role-to-ai-webapp'
  params: {
    principalId: webApp.identity.principalId
  }
}

output aiWebAppHost string = webApp.properties.defaultHostName
