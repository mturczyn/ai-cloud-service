# **Repository Overview**

This repository provides comprehensive guidance for deploying and managing an Ollama AI server, together with NGINX, acting as reverse proxy, on Azure and locally.

General idea was to:
1. Setup github actions in order to be able to create AI infrastructure in Azure automatically and deploy needed services.
2. Tear down all AI infrastructure - on Azure AI reuired expensive resources, so it is needed to remove them as quickly as possible.
3. Expose AI server, but through proxy (NGINX was chosen as proxy server), in order to secure fragile endpoints to manage AI (could incur huge costs at hosting Azure side).

Work on this repository could be splitted in two phases, each having respective markdown file with notes:

### **1. [Initial Setup with GitHub Actions and Bicep](Initial%20setup%20with%20GitHub%20Actions%20and%20Bicep.md)**
This file explains how to set up Azure infrastructure using GitHub Actions and Bicep templates. It covers creating a service principal, configuring GitHub secrets, deploying resources via Bicep scripts, and troubleshooting deployment issues.

### **2. [Setting Ollama with NGINX locally and in Azure](Setting%20Ollama%20with%20NGINX%20locally%20and%20in%20Azure.md)**  
This file focuses on setting up the Ollama AI server and NGINX with Docker, both locally and on Azure. It includes steps for pulling and running Ollama Docker images, configuring NGINX docker image, creating custom NGINX docker container and pushing Docker images to Azure Container Registry. It also covers considerations reagrding ACR credentials and problems encountered.