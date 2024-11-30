AI notes

First, we need to build docker container out of image, and upload it to Azure Container Registry

Azure Container Apps with Ollama for general AI inference
https://www.imaginarium.dev/azure-container-apps-with-ollama/

Supported by Ollama docs:
https://github.com/ollama/ollama/blob/main/docs/docker.md
https://github.com/ollama/ollama/blob/main/docs/windows.md

Migrate custom software to Azure App Service using a custom container
https://learn.microsoft.com/en-us/azure/app-service/tutorial-custom-container?tabs=azure-cli&pivots=container-linux

so far followed:

Pull the base Ollama docker image(this will take some time):
```
docker pull ollama/ollama
```
Create a container and give it a name of your choice(I called mine 'ollama'). We will also map the internal container port 11434 to our host port on 11434:
```
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```
Let's quickly verify there are no images yet in this base image (where there should be no LLMs/SLMs listed):
```
docker exec -it ollama ollama list
```
We will get ollama SLM (other can be Microsoft's Phi3.5) for the 'ollama' image (this will take some time):
```
docker exec -it ollama ollama run ollama:latest
```
After the  Ollama model is loaded (or any other Ollama compatible model of your choice), we want to commit this hydrated docker image into a new one separately. We will use the new one to exclusively push to a container registry, and continue to modify the base image to our liking locally.

Create a copy of the updated base image:
```
docker commit baseollama newtestllama
```
Push new Ollama image to Azure Container Registry

Now we can prepare and push the new Ollama image to Azure Container Registry:

Login to your existing container registry in Azure:
```
az login

az acr login -n <your_registry_name>
```
Tag your new image like the following:
```
docker tag newtestllama <acr_name>.azurecr.io/<repository_name>:latest
```
Now push the tag/versioned image to Azure Container Registry (this will take some time):
```
docker push <acr_name>.azurecr.io/<repository_name>:latest
```	
Wait until the upload process is complete here.


Ollama API docs
https://github.com/ollama/ollama/blob/main/docs/api.md#list-local-models

In order to get it to work in Azure Cloud, it was required for model to be pulled - this is just a operation in API.
So empty Ollama docker container is enough.

After pulling, we could see models inside the container with GET /api/tags request.

Then, tried to generate some answer, but got response that at least 2.8 GB of memory is required, so it required Premium Service Plan for Azure Service Plan (Server Farm). Then it finally worked.

Issues to work on: 
- create own repo for "AI backend", script it with bicep, to be deployed on demand and enabled.
- on FE, we can enable chat only if AI backend is available.


Powershell command to interact with Ollama API

(Invoke-WebRequest -method POST -uri https://ollama-huge-cost-enabled-hjb4g0b6a0b4bvgy.polandcentral-01.azurewebsites.net/api/generate -Body '{"model":"llama3.2", "prompt":"why is sky blue?", "stream":false}' ).Content | ConvertFrom-Json

base URL: https://ollama-huge-cost-enabled-hjb4g0b6a0b4bvgy.polandcentral-01.azurewebsites.net/
method: POST api/generate


AZ CLI: show webapp
```
az webapp show --name ollama-huge-cost-enabled --resource-group ollama-cost-enabled-2_group --query defaultHostName -o tsv
```

# === SUMMARY OF WORK SO FAR 

Here’s the updated **Markdown** summary with the reference:

---

# **Steps to Create and Deploy a Containerized Ollama AI Web App in Azure**

### **1. Setting up GitHub Actions with Bicep to Deploy Infrastructure**
- Followed a tutorial to configure GitHub Actions with Bicep.
- Created a service principal using the following command:
  ```bash
  az ad sp create-for-rbac --name ai-ollama --role contributor --scopes /subscriptions/<your_subscription_id>/resourceGroups/intrinsic-rg --json-auth
  ```
  - **Note:** Corrected the resource group name from `exampleRG` to `intrinsic-rg`.

---

### **2. Managing Azure Credentials and GitHub Secrets**
- Copied the JSON object containing `clientId`, `clientSecret`, `subscriptionId`, and `tenantId`.
- Created repository secrets in GitHub:
  - **AZURE_CREDENTIALS:** Pasted the full JSON output.
  - **AZURE_RG:** Resource group name (e.g., `intrinsic-rg`).
  - **AZURE_SUBSCRIPTION:** Azure subscription ID.

---

### **3. Deploying Bicep File**
- Added a Bicep file to define Azure infrastructure.
- Updated the App Service Plan resource to fix the `LinuxFxVersion` error:
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

---

### **4. Configuring the GitHub Actions Workflow (YAML Pipeline)**
- Adjusted the pipeline file to reference the deployment step and set outputs:
  ```yaml
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

---

### **5. Useful Commands to Verify and Test the Deployment**
- **Check server health:** 
  ```powershell
  (Invoke-WebRequest -method GET -uri https://ai-prod-webapp.azurewebsites.net/api/tags ).Content | ConvertFrom-Json
  ```
- **Get model list and test prompts:**
  - Retrieve model list:
    ```powershell
    (Invoke-WebRequest -method GET -uri https://ai-prod-webapp.azurewebsites.net/api/models).Content | ConvertFrom-Json
    ```
  - Send a sample prompt:
    ```powershell
    (Invoke-WebRequest -method POST -uri https://ai-prod-webapp.azurewebsites.net/api/generate -Body '{"model":"llama3.2", "prompt":"Why is the sky blue?"}').Content | ConvertFrom-Json
    ```

---

### **Reference**
For more details, refer to the official Microsoft documentation:  
[**Quickstart: Deploy Bicep files by using GitHub Actions**](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI%2Cuserlevel#code-try-2)

This workflow enables you to deploy and manage a containerized Ollama AI server on Azure seamlessly! 🚀