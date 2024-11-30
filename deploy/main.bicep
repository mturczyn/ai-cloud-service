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

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'ai-prod-webapp'
  location: resourceGroup().location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|index.docker.io/ollama/ollama:latest'
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

output aiWebAppHost string = webApp.properties.defaultHostName
