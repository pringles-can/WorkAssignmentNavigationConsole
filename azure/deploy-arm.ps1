# ARM Template Deployment Script for WANC Tracker
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanSku = "B1",
    
    [Parameter(Mandatory=$false)]
    [string]$RedisCacheSku = "Basic",
    
    [Parameter(Mandatory=$false)]
    [string]$RedisCacheSize = "C0",
    
    [Parameter(Mandatory=$false)]
    [string]$SignalRSku = "Free_F1",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSignalR,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipContainerRegistry
)

Write-Host "Deploying WANC Tracker using ARM Template..." -ForegroundColor Green

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

# Create Resource Group if it doesn't exist
Write-Host "Creating/verifying Resource Group..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location

# Prepare parameters for ARM template
$parameters = @{
    "resourceGroupName" = $ResourceGroupName
    "location" = $Location
    "environment" = $Environment
    "appServicePlanSku" = $AppServicePlanSku
    "redisCacheSku" = $RedisCacheSku
    "redisCacheSize" = $RedisCacheSize
    "signalRSku" = $SignalRSku
    "deploySignalR" = -not $SkipSignalR
    "deployContainerRegistry" = -not $SkipContainerRegistry
}

# Convert parameters to JSON
$parametersJson = $parameters | ConvertTo-Json -Depth 3

# Deploy ARM template
Write-Host "Deploying ARM template..." -ForegroundColor Cyan
$deploymentName = "wanc-deploy-$(Get-Date -Format 'MMdd-HHmm')"

az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "azuredeploy.json" `
    --parameters $parametersJson `
    --name $deploymentName

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nARM Template Deployment Successful!" -ForegroundColor Green
    
    # Get deployment outputs
    $outputs = az deployment group show --resource-group $ResourceGroupName --name $deploymentName --query properties.outputs | ConvertFrom-Json
    
    Write-Host "`nDeployed Resources:" -ForegroundColor Yellow
    Write-Host "  Resource Group: $($outputs.resourceGroupName.value)"
    Write-Host "  App Service: $($outputs.appServiceName.value)"
    Write-Host "  App Service URL: $($outputs.appServiceUrl.value)"
    Write-Host "  Redis Cache: $($outputs.redisCacheName.value)"
    Write-Host "  Key Vault: $($outputs.keyVaultName.value)"
    
    if ($outputs.containerRegistryName.value) {
        Write-Host "  Container Registry: $($outputs.containerRegistryName.value)"
    }
    
    if ($outputs.signalRName.value) {
        Write-Host "  SignalR Service: $($outputs.signalRName.value)"
    }
    
    # Configure connection strings and secrets
    Write-Host "`nConfiguring connection strings and secrets..." -ForegroundColor Cyan
    
    # Get Redis connection string
    $redisKeys = az redis list-keys --name $outputs.redisCacheName.value --resource-group $ResourceGroupName | ConvertFrom-Json
    $redisHost = az redis show --name $outputs.redisCacheName.value --resource-group $ResourceGroupName --query hostName --output tsv
    $redisPort = az redis show --name $outputs.redisCacheName.value --resource-group $ResourceGroupName --query port --output tsv
    $redisConnectionString = "$redisHost:$redisPort,password=$($redisKeys.primaryKey),ssl=True,abortConnect=False"
    
    # Store Redis connection string in Key Vault
    az keyvault secret set --vault-name $outputs.keyVaultName.value --name "RedisConnectionString" --value $redisConnectionString
    
    # Configure SignalR if deployed
    if ($outputs.signalRName.value) {
        $signalRKeys = az signalr key list --name $outputs.signalRName.value --resource-group $ResourceGroupName | ConvertFrom-Json
        $signalRHost = az signalr show --name $outputs.signalRName.value --resource-group $ResourceGroupName --query hostName --output tsv
        $signalRConnectionString = "Endpoint=https://$signalRHost;AccessKey=$($signalRKeys.primaryKey);Version=1.0;"
        
        # Store SignalR connection string in Key Vault
        az keyvault secret set --vault-name $outputs.keyVaultName.value --name "SignalRConnectionString" --value $signalRConnectionString
    }
    
    # Configure App Service with connection strings
    $appSettings = @{
        "Redis:ConnectionString" = $redisConnectionString
    }
    
    if ($outputs.signalRName.value) {
        $appSettings["Azure:SignalR:ConnectionString"] = $signalRConnectionString
    }
    
    # Apply app settings
    foreach ($setting in $appSettings.GetEnumerator()) {
        az webapp config appsettings set --name $outputs.appServiceName.value --resource-group $ResourceGroupName --settings "$($setting.Key)=$($setting.Value)"
    }
    
    # Enable managed identity access to Key Vault
    $identityPrincipalId = az webapp identity show --name $outputs.appServiceName.value --resource-group $ResourceGroupName --query principalId --output tsv
    az keyvault set-policy --name $outputs.keyVaultName.value --object-id $identityPrincipalId --secret-permissions get list
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. Build and push your Docker image:"
    if ($outputs.containerRegistryName.value) {
        $acrLoginServer = az acr show --name $outputs.containerRegistryName.value --query loginServer --output tsv
        Write-Host "   docker build -t $acrLoginServer/wanc-tracker ."
        Write-Host "   az acr login --name $($outputs.containerRegistryName.value)"
        Write-Host "   docker push $acrLoginServer/wanc-tracker:latest"
    }
    Write-Host "2. Deploy your application:"
    Write-Host "   az webapp restart --name $($outputs.appServiceName.value) --resource-group $ResourceGroupName"
    Write-Host "3. Access your application:"
    Write-Host "   $($outputs.appServiceUrl.value)"
    
    # Save deployment info
    $deploymentInfo = @{
        ResourceGroupName = $outputs.resourceGroupName.value
        AppServiceName = $outputs.appServiceName.value
        AppServiceUrl = $outputs.appServiceUrl.value
        RedisName = $outputs.redisCacheName.value
        KeyVaultName = $outputs.keyVaultName.value
        ContainerRegistryName = $outputs.containerRegistryName.value
        SignalRName = $outputs.signalRName.value
        DeploymentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        DeploymentName = $deploymentName
    }
    
    $deploymentInfo | ConvertTo-Json -Depth 3 | Out-File -FilePath "azure-arm-deployment-$Environment.json" -Encoding UTF8
    Write-Host "`nDeployment information saved to: azure-arm-deployment-$Environment.json" -ForegroundColor Cyan
    
} else {
    Write-Error "ARM template deployment failed!"
    exit 1
}
