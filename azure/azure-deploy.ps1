# Azure Deployment Script for Work Assignment Navigation Console
# This script creates all necessary Azure resources

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$true)]
    [string]$Environment = "dev", # dev, staging, prod
    
    [string]$AppServicePlanSku = "B1",
    
    [switch]$SkipContainerRegistry,
    
    [switch]$SkipSignalR
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🍕 Deploying Work Assignment Navigation Tracker Azure Resources..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Generate unique names
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$uniqueSuffix = "$Environment-$timestamp"
$redisName = "wanc-redis-$uniqueSuffix"
$appServiceName = "wanc-app-$uniqueSuffix"
$appServicePlanName = "wanc-plan-$uniqueSuffix"
$containerRegistryName = "wancregistry$($uniqueSuffix -replace '-', '')"
$signalRName = "wanc-signalr-$uniqueSuffix"
$keyVaultName = "wanc-kv-$uniqueSuffix"

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Check if logged in to Azure
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Please log in to Azure..." -ForegroundColor Yellow
    az login
}

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location

# Create Key Vault for secrets
Write-Host "Creating Key Vault..." -ForegroundColor Cyan
az keyvault create --name $keyVaultName --resource-group $ResourceGroupName --location $Location --sku standard

# Get current user object ID for Key Vault access
$currentUser = az ad signed-in-user show | ConvertFrom-Json
az keyvault set-policy --name $keyVaultName --object-id $currentUser.id --secret-permissions get set list delete

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Cyan
az appservice plan create --name $appServicePlanName --resource-group $ResourceGroupName --location $Location --sku $AppServicePlanSku --is-linux

# Create Azure Container Registry (if not skipped)
if (-not $SkipContainerRegistry) {
    Write-Host "Creating Azure Container Registry..." -ForegroundColor Cyan
    az acr create --name $containerRegistryName --resource-group $ResourceGroupName --location $Location --sku Basic --admin-enabled true
    
    # Get ACR credentials
    $acrCredentials = az acr credential show --name $containerRegistryName | ConvertFrom-Json
    $acrLoginServer = az acr show --name $containerRegistryName --query loginServer --output tsv
    
    # Store ACR credentials in Key Vault
    az keyvault secret set --vault-name $keyVaultName --name "AcrUsername" --value $acrCredentials.username
    az keyvault secret set --vault-name $keyVaultName --name "AcrPassword" --value $acrCredentials.passwords[0].value
    az keyvault secret set --vault-name $keyVaultName --name "AcrLoginServer" --value $acrLoginServer
}

# Create Azure Redis Cache
Write-Host "Creating Azure Redis Cache..." -ForegroundColor Cyan
az redis create --name $redisName --resource-group $ResourceGroupName --location $Location --sku Basic --vm-size C0

# Get Redis connection string
$redisKeys = az redis list-keys --name $redisName --resource-group $ResourceGroupName | ConvertFrom-Json
$redisHost = az redis show --name $redisName --resource-group $ResourceGroupName --query hostName --output tsv
$redisPort = az redis show --name $redisName --resource-group $ResourceGroupName --query port --output tsv
$redisConnectionString = "$redisHost:$redisPort,password=$($redisKeys.primaryKey),ssl=True,abortConnect=False"

# Store Redis connection string in Key Vault
az keyvault secret set --vault-name $keyVaultName --name "RedisConnectionString" --value $redisConnectionString

# Create Azure SignalR Service (if not skipped)
$signalRConnectionString = ""
if (-not $SkipSignalR) {
    Write-Host "Creating Azure SignalR Service..." -ForegroundColor Cyan
    az signalr create --name $signalRName --resource-group $ResourceGroupName --location $Location --sku Free_F1
    
    # Get SignalR connection string
    $signalRKeys = az signalr key list --name $signalRName --resource-group $ResourceGroupName | ConvertFrom-Json
    $signalRHost = az signalr show --name $signalRName --resource-group $ResourceGroupName --query hostName --output tsv
    $signalRConnectionString = "Endpoint=https://$signalRHost;AccessKey=$($signalRKeys.primaryKey);Version=1.0;"
    
    # Store SignalR connection string in Key Vault
    az keyvault secret set --vault-name $keyVaultName --name "SignalRConnectionString" --value $signalRConnectionString
}

# Create App Service
Write-Host "Creating App Service..." -ForegroundColor Cyan
az webapp create --name $appServiceName --resource-group $ResourceGroupName --plan $appServicePlanName --deployment-local-git

# Configure App Service settings
Write-Host "Configuring App Service settings..." -ForegroundColor Cyan

# Get Key Vault URL
$keyVaultUrl = az keyvault show --name $keyVaultName --query properties.vaultUri --output tsv

# Configure app settings
$appSettings = @{
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_ENABLE_CI" = "true"
    "WEBSITES_PORT" = "8080"
    "ASPNETCORE_ENVIRONMENT" = $Environment
    "KeyVault:VaultUri" = $keyVaultUrl
}

# Add Redis connection string
if ($redisConnectionString) {
    $appSettings["Redis:ConnectionString"] = $redisConnectionString
}

# Add SignalR connection string
if ($signalRConnectionString) {
    $appSettings["Azure:SignalR:ConnectionString"] = $signalRConnectionString
}

# Apply app settings
foreach ($setting in $appSettings.GetEnumerator()) {
    az webapp config appsettings set --name $appServiceName --resource-group $ResourceGroupName --settings "$($setting.Key)=$($setting.Value)"
}

# Configure container deployment
if (-not $SkipContainerRegistry) {
    Write-Host "Configuring container deployment..." -ForegroundColor Cyan
    az webapp config container set --name $appServiceName --resource-group $ResourceGroupName --docker-custom-image-name "$acrLoginServer/wanc-tracker:latest"
}

# Enable managed identity for Key Vault access
Write-Host "Enabling managed identity..." -ForegroundColor Cyan
az webapp identity assign --name $appServiceName --resource-group $ResourceGroupName

# Get managed identity principal ID
$identityPrincipalId = az webapp identity show --name $appServiceName --resource-group $ResourceGroupName --query principalId --output tsv

# Grant Key Vault access to managed identity
az keyvault set-policy --name $keyVaultName --object-id $identityPrincipalId --secret-permissions get list

# Output deployment summary
Write-Host "`n🍕 Azure Resources Deployment Complete!" -ForegroundColor Green
Write-Host "`nDeployed Resources:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Key Vault: $keyVaultName"
Write-Host "  App Service Plan: $appServicePlanName"
Write-Host "  App Service: $appServiceName"
Write-Host "  Redis Cache: $redisName"
if (-not $SkipContainerRegistry) {
    Write-Host "  Container Registry: $containerRegistryName"
}
if (-not $SkipSignalR) {
    Write-Host "  SignalR Service: $signalRName"
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Build and push your Docker image:"
if (-not $SkipContainerRegistry) {
    Write-Host "   docker build -t $acrLoginServer/wanc-tracker ."
    Write-Host "   az acr login --name $containerRegistryName"
    Write-Host "   docker push $acrLoginServer/wanc-tracker:latest"
}
Write-Host "2. Deploy your application:"
Write-Host "   az webapp restart --name $appServiceName --resource-group $ResourceGroupName"
Write-Host "3. Access your application:"
Write-Host "   https://$appServiceName.azurewebsites.net"

# Save deployment info to file
$deploymentInfo = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Environment = $Environment
    AppServiceName = $appServiceName
    RedisName = $redisName
    KeyVaultName = $keyVaultName
    ContainerRegistryName = if (-not $SkipContainerRegistry) { $containerRegistryName } else { $null }
    SignalRName = if (-not $SkipSignalR) { $signalRName } else { $null }
    DeploymentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$deploymentInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath "azure-deployment-$Environment.json" -Encoding UTF8
Write-Host "`nDeployment information saved to: azure-deployment-$Environment.json" -ForegroundColor Cyan
