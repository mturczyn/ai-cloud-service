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