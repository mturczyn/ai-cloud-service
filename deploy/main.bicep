@description('Full name (with image name and tag) to docker image.')
param dockerImageName string

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
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'sitecontainers'
      // Explicitly disabling managed identity for ACR
      acrUseManagedIdentityCreds: false
    }
  }
}

@description('Main NGINX container.')
resource nginxContainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: webApp
  name: 'nginx'
  properties: {
    image: dockerImageName
    isMain: true
    targetPort: '80'
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
  }
}

output aiWebAppHost string = webApp.properties.defaultHostName
