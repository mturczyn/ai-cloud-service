# **Deploying AI server with GitHub actions**

This document outlines the steps to deploy a containerized Ollama AI server using Azure and GitHub Actions, along with workflows for managing resources.

---

## **Setup Process**

### **Step 1: Create a Service Principal**
Use the `az ad sp create-for-rbac` command to create a service principal for GitHub Actions. Grant it the minimum required access (Contributor role for the resource group).

```bash
az ad sp create-for-rbac --name ai-ollama --role contributor \
  --scopes /subscriptions/6c031f3a-0aa5-480d-b2ec-272b24779509/resourceGroups/intrinsic-rg \
  --json-auth
```

Save the output JSON:
```json
{
  "clientId": "c7e61991-f66b-4ced-b30c-c99169122c8f",
  "clientSecret": "secret-value",
  "subscriptionId": "6c031f3a-0aa5-480d-b2ec-272b24779519",
  "tenantId": "7a909574-a39d-4a01-8c65-02bc2faea5b9"
}
```
Ensure no trailing commas in the JSON to avoid errors like:  
`Login failed with Error: Content isn't a valid JSON object.`

---

### **Step 2: Configure GitHub Secrets**
1. Go to **Settings > Secrets and variables > Actions** in your GitHub repository.
2. Add the following secrets:
   - **AZURE_CREDENTIALS:** Paste the full JSON output from Step 1.
   - **AZURE_RG:** The name of your Azure resource group (e.g., `intrinsic-rg`).
   - **AZURE_SUBSCRIPTION:** Your Azure subscription ID (e.g., `6c031f3a-0aa5-480d-b2ec-272b24779509`).

---

### **Step 3: Write a Bicep File for Deployment**
Define your infrastructure in a `main.bicep` file. For example, create an App Service Plan:

```bicep
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'ai-prod-asp-temp'
  location: resourceGroup().location
  sku: {
    name: 'P3v3'
    tier: 'PremiumV3'
    capacity: 1
  }
  properties: {
    reserved: true // Ensures Linux-based App Service Plan
  }
}
```
The `reserved: true` property resolves the "LinuxFxVersion has an invalid value" error.

---

### **Step 4: Define GitHub Workflows**

#### **A. Deployment Workflow**
This workflow deploys the Bicep file and sets up the AI server.

```yaml
name: Deploy AI Server

on:
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@main

      - name: Log into Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Ollama Server
        id: deployOllama
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION }}
          resourceGroupName: ${{ secrets.AZURE_RG }}
          template: ./deploy/main.bicep
          failOnStdErr: false

    outputs:
      aiWebAppHost: ${{ steps.deployOllama.outputs.aiWebAppHost }}
```
**Note:** `deployOllama` is used as `id` for the step, as it is used later to reference output variables.

#### **B. Cleanup Workflow**
This workflow removes resources related to the AI server using Azure CLI commands.

```yaml
name: Remove AI Resources
on: [workflow_dispatch]

jobs:
  remove-ai-resources:
    runs-on: ubuntu-latest
    steps:
    - name: Log into Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Azure CLI - Remove AI resources
      uses: azure/cli@v2
      with:
        azcliversion: latest
        inlineScript: |
          az resource delete --resource-group ${{ secrets.AZURE_RG }} --name ai-prod-webapp --resource-type 'Microsoft.Web/sites'
          az resource delete --resource-group ${{ secrets.AZURE_RG }} --name ai-prod-asp --resource-type 'Microsoft.Web/serverfarms'
```

---

## **Verification**

### **Check the Deployed AI Server**
Run the following PowerShell command to check server health:
```powershell
(Invoke-WebRequest -method GET -uri https://ai-prod-webapp.azurewebsites.net/api/tags).Content | ConvertFrom-Json
```

### **Test AI Functionality**

For full Ollama API docs, refer to this [page](https://github.com/ollama/ollama/blob/main/docs/api.md).

- **List available models:**
  ```powershell
  (Invoke-WebRequest -method GET -uri https://ai-prod-webapp.azurewebsites.net/api/models).Content | ConvertFrom-Json
  ```
- **Generate a response for a prompt:**
  ```powershell
  (Invoke-WebRequest -method POST -uri https://ai-prod-webapp.azurewebsites.net/api/generate -Body '{"model":"llama3.2", "prompt":"Why is the sky blue?"}').Content | ConvertFrom-Json
  ```

---

## **Miscellaneous Notes**

### **How to Pull and Push Ollama Server**
1. **Pull the base Ollama Docker image:**
   ```bash
   docker pull ollama/ollama
   ```

2. **Create a container and map the internal port:**
   ```bash
   docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
   ```

3. **Verify the base image has no models:**
   ```bash
   docker exec -it ollama ollama list
   ```

4. **Get and hydrate the Ollama SLM:**
   ```bash
   docker exec -it ollama ollama run ollama:latest
   ```

5. **Commit the hydrated image:**
   ```bash
   docker commit ollama newtestllama
   ```

6. **Push the image to Azure Container Registry:**
   - Login:
     ```bash
     az login
     az acr login -n <your_registry_name>
     ```
   - Tag the image:
     ```bash
     docker tag newtestllama <acr_name>.azurecr.io/<repository_name>:latest
     ```
   - Push the image:
     ```bash
     docker push <acr_name>.azurecr.io/<repository_name>:latest
     ```

---

## **References**
- [Quickstart: Deploy Bicep files by using GitHub Actions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI%2Cuserlevel#code-try-2)
- [Azure Container Apps with Ollama](https://www.imaginarium.dev/azure-container-apps-with-ollama/)
- [Ollama Docker Documentation](https://github.com/ollama/ollama/blob/main/docs/docker.md)
- [Tutorial: Custom Containers in Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/tutorial-custom-container?tabs=azure-cli&pivots=container-linux)

---
