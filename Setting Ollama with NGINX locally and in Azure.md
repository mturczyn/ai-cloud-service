# **Summary of AI Server Deployment and Reverse Proxy Configuration**

This document summarizes the process of setting up an AI server locally and deploying it to Azure with security and scalability considerations, including the use of NGINX as a reverse proxy and deploying multiple containers to an Azure Web App.

---

## **1. Securing the AI API with NGINX Reverse Proxy**

To secure the AI API:
- NGINX was configured to handle all incoming requests on port 80.
- It returns `404` for unauthorized or invalid paths.
- Only three endpoints (`/api/tags`, `/api/pull`, `/api/generate`) are authorized, requiring a specific `Authorization` header. Successful requests are forwarded to the AI API (Ollama server).

### **NGINX Configuration**
```nginx
server {
    listen 80;

    location /api/tags {
        if ($http_authorization != "Bearer 1234") {
            return 404;
        }
        proxy_pass http://localhost:11434/api/tags;
        proxy_set_header Host localhost:11434;
    }

    location /api/pull {
        if ($http_authorization != "Bearer 1234") {
            return 404;
        }
        proxy_pass http://localhost:11434/api/pull;
        proxy_set_header Host localhost:11434;
    }

    location /api/generate {
        if ($http_authorization != "Bearer 1234") {
            return 404;
        }
        proxy_pass http://localhost:11434/api/generate;
        proxy_set_header Host localhost:11434;
    }

    location / {
        return 404;
    }
}
```

---

## **2. Running NGINX and Ollama in Docker**

### **Initial Challenge**
Initially, an attempt was made to define a single Dockerfile that would contain both NGINX and Ollama. However, this approach proved problematic:
- Docker does not natively support running multiple services in one container without complex configurations.
- When using two base images in a single Dockerfile, only one service typically works while the other remains inaccessible.

### **Solution**
This issue was discussed on [this Stack Overflow post](https://stackoverflow.com/questions/79242550/running-rest-api-ollama-and-nginx-reverse-proxy/79242675). The key insights were:
- **Alternative 1**: Use a single Docker container by installing additional software within the container. For example, NGINX can be added to the base container hosting Ollama. However, this is **not recommended** as it complicates container management and violates the principle of one service per container.
- **Alternative 2 (Recommended)**: Use **separate Docker containers** for each service and wire them together using a `docker-compose.yaml` file. This approach ensures better modularity and scalability.

### **Docker Compose Example**
```yaml
version: '3.8'
services:
  nginx:
    image: my-nginx:latest
    ports:
      - '8080:80'
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
  ollama:
    image: ollama/ollama:latest
```

### **Steps to Run Locally**
1. Create a `docker-compose.yaml` file as shown above.
2. Use the following command to start both containers:
   ```bash
   docker compose up -d
   ```

This approach worked perfectly for local setups. However, Azure Web Apps does not directly support Docker Compose, necessitating alternative deployment strategies for Azure.

---

## **3. Deploying to Azure with Sidecar Containers**

Azure Web Apps supports multiple containers using **sidecar containers**. The NGINX and Ollama containers were deployed to a single Azure Web App.

### **Bicep File Example**
```bicep
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'ai-prod-asp'
  location: resourceGroup().location
  sku: {
    name: 'P3v3'
    tier: 'PremiumV3'
    capacity: 1
  }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'ai-prod-webapp'
  location: resourceGroup().location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|nginx:latest'
      acrUseManagedIdentityCreds: false
    }
  }
}

resource nginxContainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: webApp
  name: 'nginx'
  properties: {
    image: '<your-acr-name>.azurecr.io/nginx:latest'
    userName: '<your-acr-username>'
    passwordSecret: '<your-acr-password>'
  }
}
```

---

## **4. Configuring ACR Credentials**

When deploying with Bicep, the default configuration might not properly set ACR credentials. Two solutions were explored:

### **Solution 1: Assign `AcrPull` Role to Web App**
1. Grant the Web App access to the ACR using the `AcrPull` role.
2. CLI Command:
   ```bash
   az role assignment create \
     --assignee <webapp-principal-id> \
     --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.ContainerRegistry/registries/<acr-name> \
     --role AcrPull
   ```
This then was scripted in Bicep file (role assignment for webapp). However this required GitHub agent to have permission to manage roles in Azure. So this command was used:
```
az role assignment create --assignee 2e0ca407-7242-4a39-9896-c66eed4f8f0b --role "User Access Administrator" --scope /subscriptions/6c031f3a-0aa5-480d-b2ec-272b24779509
```
But after solving it differently, this assignment could be security risk, so the role was removed using below AZ CLI command:
```
az role assignment delete --assignee 2e0ca407-7242-4a39-9896-c66eed4f8f0b --role "User Access Administrator" --scope /subscriptions/6c031f3a-0aa5-480d-b2ec-272b24779509
```

### **Solution 2: Explicit Credentials**
Define `acrUseManagedIdentityCreds: false` in webapp properties and specify credentials directly in the site container definition:
```bicep
userName: '<your-acr-username>'
passwordSecret: '<your-acr-password>'
```

---

## **5. Additional NGINX Notes**

- **Test Configuration**:
  ```bash
  sudo nginx -t
  ```
- **Reload Configuration**:
  ```bash
  sudo systemctl reload nginx
  ```
- **Debugging Logs**:
  ```bash
  sudo tail -f /var/log/nginx/error.log
  ```
- **Serve Static Files**:
  ```nginx
  location /api/tags {
      alias /usr/share/nginx/html/tags.html;
      default_type text/html;
  }
  ```

---

## **6. Debugging in Azure**

### **Check Sidecar Containers**
```bash
az webapp show --name <webapp-name> --resource-group <resource-group> --query "siteConfig.containerSettings"
```

### **Check Deployment Logs**
```bash
az webapp log tail --name <webapp-name> --resource-group <resource-group>
```

---

This comprehensive approach ensures secure, scalable, and containerized deployment of the AI server with NGINX reverse proxy on Azure.