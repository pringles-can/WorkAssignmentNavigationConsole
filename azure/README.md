# Azure Infrastructure Setup Guide

This guide will help you set up all the necessary Azure resources for your WANC Tracker application.

## 📋 Prerequisites

1. **Azure Subscription** - You need an active Azure subscription
2. **Azure CLI** - Install from [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **PowerShell** (for Windows users) or **Bash** (for Linux/macOS users)
4. **Docker** - For building and pushing container images

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

#### Using PowerShell Script:
```powershell
# Navigate to the azure directory
cd azure

# Deploy all resources
.\azure-deploy.ps1 -ResourceGroupName "wanc-tracker-dev" -Environment "dev" -Location "East US"
```

#### Using ARM Template:
```powershell
# Navigate to the azure directory
cd azure

# Deploy using ARM template
.\deploy-arm.ps1 -ResourceGroupName "wanc-tracker-dev" -Environment "dev"
```

### Option 2: Manual Deployment

Follow the step-by-step instructions below.

## 📦 Azure Resources Overview

The following resources will be created:

| Resource | Purpose | SKU | Estimated Cost/Month |
|----------|---------|-----|---------------------|
| **Resource Group** | Container for all resources | - | Free |
| **App Service Plan** | Hosting plan for web app | B1 | ~$13 |
| **App Service** | Web application hosting | - | Included in plan |
| **Azure Redis Cache** | Order data storage | Basic C0 | ~$13 |
| **Azure SignalR Service** | Real-time communication | Free F1 | Free |
| **Azure Container Registry** | Docker image storage | Basic | ~$5 |
| **Key Vault** | Secret management | Standard | ~$3 |

**Total Estimated Cost: ~$34/month**

## Step-by-Step Manual Setup

### 1. Login to Azure
```bash
az login
```

### 2. Create Resource Group
```bash
az group create --name "wanc-tracker-dev" --location "East US"
```

### 3. Create Key Vault
```bash
az keyvault create --name "wanc-kv-dev" --resource-group "wanc-tracker-dev" --location "East US" --sku standard
```

### 4. Create App Service Plan
```bash
az appservice plan create --name "wanc-plan-dev" --resource-group "wanc-tracker-dev" --location "East US" --sku B1 --is-linux
```

### 5. Create Azure Container Registry
```bash
az acr create --name "wancregistrydev" --resource-group "wanc-tracker-dev" --location "East US" --sku Basic --admin-enabled true
```

### 6. Create Azure Redis Cache
```bash
az redis create --name "wanc-redis-dev" --resource-group "wanc-tracker-dev" --location "East US" --sku Basic --vm-size C0
```

### 7. Create Azure SignalR Service
```bash
az signalr create --name "wanc-signalr-dev" --resource-group "wanc-tracker-dev" --location "East US" --sku Free_F1
```

### 8. Create App Service
```bash
az webapp create --name "wanc-app-dev" --resource-group "wanc-tracker-dev" --plan "wanc-plan-dev" --deployment-local-git
```

### 9. Configure App Service
```bash
# Enable managed identity
az webapp identity assign --name "wanc-app-dev" --resource-group "wanc-tracker-dev"

# Configure app settings
az webapp config appsettings set --name "wanc-app-dev" --resource-group "wanc-tracker-dev" --settings \
  "WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" \
  "DOCKER_ENABLE_CI=true" \
  "WEBSITES_PORT=8080" \
  "ASPNETCORE_ENVIRONMENT=Production"
```

### 10. Get Connection Strings
```bash
# Get Redis connection string
REDIS_KEYS=$(az redis list-keys --name "wanc-redis-dev" --resource-group "wanc-tracker-dev")
REDIS_HOST=$(az redis show --name "wanc-redis-dev" --resource-group "wanc-tracker-dev" --query hostName --output tsv)
REDIS_PASSWORD=$(echo $REDIS_KEYS | jq -r '.primaryKey')
REDIS_CONNECTION_STRING="$REDIS_HOST:6380,password=$REDIS_PASSWORD,ssl=True,abortConnect=False"

# Get SignalR connection string
SIGNALR_KEYS=$(az signalr key list --name "wanc-signalr-dev" --resource-group "wanc-tracker-dev")
SIGNALR_HOST=$(az signalr show --name "wanc-signalr-dev" --resource-group "wanc-tracker-dev" --query hostName --output tsv)
SIGNALR_PASSWORD=$(echo $SIGNALR_KEYS | jq -r '.primaryKey')
SIGNALR_CONNECTION_STRING="Endpoint=https://$SIGNALR_HOST;AccessKey=$SIGNALR_PASSWORD;Version=1.0;"
```

### 11. Store Secrets in Key Vault
```bash
# Store connection strings in Key Vault
az keyvault secret set --vault-name "wanc-kv-dev" --name "RedisConnectionString" --value "$REDIS_CONNECTION_STRING"
az keyvault secret set --vault-name "wanc-kv-dev" --name "SignalRConnectionString" --value "$SIGNALR_CONNECTION_STRING"
```

### 12. Configure App Service with Connection Strings
```bash
az webapp config appsettings set --name "wanc-app-dev" --resource-group "wanc-tracker-dev" --settings \
  "Redis:ConnectionString=$REDIS_CONNECTION_STRING" \
  "Azure:SignalR:ConnectionString=$SIGNALR_CONNECTION_STRING"
```

## 🐳 Deploy Your Application

### 1. Build Docker Image
```bash
# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name "wancregistrydev" --query loginServer --output tsv)

# Build image
docker build -t $ACR_LOGIN_SERVER/wanc-tracker:latest .
```

### 2. Push to Azure Container Registry
```bash
# Login to ACR
az acr login --name "wancregistrydev"

# Push image
docker push $ACR_LOGIN_SERVER/wanc-tracker:latest
```

### 3. Deploy to App Service
```bash
# Configure container deployment
az webapp config container set --name "wanc-app-dev" --resource-group "wanc-tracker-dev" --docker-custom-image-name "$ACR_LOGIN_SERVER/wanc-tracker:latest"

# Restart app service
az webapp restart --name "wanc-app-dev" --resource-group "wanc-tracker-dev"
```

## 🔄 CI/CD with GitHub Actions

### 1. Set up Azure Service Principal
```bash
# Create service principal
az ad sp create-for-rbac --name "wanc-tracker-sp" --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/wanc-tracker-dev --sdk-auth
```

### 2. Add GitHub Secrets
Add the following secrets to your GitHub repository:

- `AZURE_CREDENTIALS`: The JSON output from the service principal creation
- `REGISTRY_USERNAME`: ACR username (from `az acr credential show`)
- `REGISTRY_PASSWORD`: ACR password (from `az acr credential show`)

### 3. Configure GitHub Actions
The workflow file `.github/workflows/azure-deploy.yml` is already configured and will:

- Build and push Docker images
- Deploy to Azure App Service
- Configure connection strings
- Run smoke tests

## 🔍 Monitoring and Troubleshooting

### Check App Service Logs
```bash
az webapp log tail --name "wanc-app-dev" --resource-group "wanc-tracker-dev"
```

### Check Redis Connection
```bash
# Test Redis connection
az redis show --name "wanc-redis-dev" --resource-group "wanc-tracker-dev" --query provisioningState
```

### Check SignalR Service
```bash
# Test SignalR service
az signalr show --name "wanc-signalr-dev" --resource-group "wanc-tracker-dev" --query provisioningState
```

### App Service Health Check
```bash
# Get app service URL
APP_URL=$(az webapp show --name "wanc-app-dev" --resource-group "wanc-tracker-dev" --query defaultHostName --output tsv)
echo "https://$APP_URL"

# Test health endpoint
curl https://$APP_URL/health
```

## 🧹 Cleanup

To remove all resources and avoid charges:

```bash
# Delete resource group (this removes all resources)
az group delete --name "wanc-tracker-dev" --yes --no-wait
```

## 📊 Cost Optimization

### Development Environment
- Use Basic SKU for Redis Cache (C0)
- Use Free SKU for SignalR Service
- Use Basic SKU for Container Registry
- Use B1 SKU for App Service Plan

### Production Environment
- Consider Standard SKU for Redis Cache (C1 or higher)
- Use Standard SKU for SignalR Service
- Use Standard SKU for Container Registry
- Use S1 or higher for App Service Plan

## 🔐 Security Best Practices

1. **Use Managed Identity** for App Service to access Key Vault
2. **Store all secrets** in Azure Key Vault
3. **Enable SSL/TLS** for all connections
4. **Use Azure Private Link** for production environments
5. **Enable Azure Security Center** monitoring
6. **Regular security updates** for container images

## 📞 Support

If you encounter issues:

1. Check the [Azure Status Page](https://status.azure.com/)
2. Review [Azure Documentation](https://docs.microsoft.com/azure/)
3. Use [Azure CLI Troubleshooting Guide](https://docs.microsoft.com/en-us/cli/azure/use-cli-effectively)
4. Check [GitHub Issues](https://github.com/your-repo/issues) for known problems
