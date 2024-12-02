param azureContainerRegistryCreds string

var acrCreds = json(azureContainerRegistryCreds)
output o string =azureContainerRegistryCreds
// @description('Main App Service Plan.')
// resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
//   name: 'ai-prod-asp'
//   location: resourceGroup().location
//   sku: {
//     name: 'P3v3'
//     tier: 'PremiumV3'
//     capacity: 1
//   }
//   properties: {
//     // Ensuring that this is a Linux-based App Service Plan
//     reserved: true
//   }
// }

// @description('Main Web App resource.')
// resource webApp 'Microsoft.Web/sites@2023-01-01' = {
//   name: 'ai-prod-webapp'
//   location: resourceGroup().location
//   kind: 'app,linux'
//   properties: {
//     serverFarmId: appServicePlan.id
//     siteConfig: {
//       linuxFxVersion: 'sitecontainers'
//       // alwaysOn: true
//       appSettings: [
//         {
//           name: 'DOCKER_REGISTRY_SERVER_URL'
//           value: 'https://intrinsicweb.azurecr.io' // Replace with your ACR URL
//         }
//         {
//           name: 'DOCKER_REGISTRY_SERVER_USERNAME'
//           value: acrCreds.applicationId // Replace with the ACR admin username
//         }
//         {
//           name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
//           value: acrCreds.clientSecret // Replace with the ACR admin password
//         }
//         {
//           name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
//           value: 'false'
//         }
//       ]
//       // appSettings: [
//       //   {
//       //     name: 'DOCKER_REGISTRY_SERVER_URL'
//       //     value: 'https://index.docker.io'
//       //   }
//       //   {
//       //     name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
//       //     value: 'false'
//       //   }
//       // ]
//     }
//   }
// }

// @description('Main NGINX container.')
// resource nginxContainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
//   parent: webApp
//   name: 'nginx'
//   properties: {
//     image: 'intrinsicweb.azurecr.io/tests/configured-nginx:latest' // NGINX image
//     isMain: true // Indicates this is the main container
//     targetPort: '80' // Target port for NGINX
//     environmentVariables: [
//       {
//         name: 'NGINX_ENV_VAR'
//         value: 'example-value' // Replace with required environment variables for NGINX
//       }
//     ]
//   }
// }

// @description('Sidecar container for Ollama.')
// resource ollamaContainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
//   parent: webApp
//   name: 'ollama'
//   properties: {
//     image: 'ollama/ollama:latest' // Docker Hub image
//     isMain: false // Indicates this is a sidecar container
//     // targetPort: '11434' // Target port for Ollama
//     // environmentVariables: [
//     //   {
//     //     name: 'OLLAMA_ENV_VAR'
//     //     value: 'example-value' // Replace with any required environment variables
//     //   }
//     // ]
//   }
// }

// output aiWebAppHost string = webApp.properties.defaultHostName
