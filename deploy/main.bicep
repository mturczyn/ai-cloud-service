// @description('Name of the App Service Plan')
// param appServicePlanName string

// @description('Name of the Web App')
// param webAppName string

// @description('Location for the resources')
// param location string = resourceGroup().location

// @description('Docker image name from Docker Hub')
// param dockerImage string

// @description('Docker Hub username for authentication (if required)')
// param dockerUsername string = ''

// @description('Docker Hub password for authentication (if required)')
// param dockerPassword string = ''

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'ai-prod-asp'
  location: resourceGroup().location
  sku: {
    name: 'P3v3'
    tier: 'PremiumV3'
    capacity: 1 // You can adjust the capacity (number of instances) if needed
  }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'ai-prod-webapp'
  location: resourceGroup().location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|ollama/ollama:latest' // Specifies the Docker image from Docker Hub
    }
    appSettings: [
      {
        name: 'DOCKER_REGISTRY_SERVER_URL'
        value: 'https://hub.docker.com/r/'
      }
    ]
  }
}