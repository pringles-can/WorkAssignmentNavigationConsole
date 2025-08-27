# Complete Deployment Script for WANC Application
# This script checks for existing resources and completes the deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev",
    
    [string]$AppServicePlanSku = "F1",
    
    [switch]$SkipContainerRegistry,
    
    [switch]$SkipSignalR
)

# Set error action preference
$ErrorActionPreference = "Continue"

Write-Host "Completing WANC Application Deployment..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Generate resource names (same as original script)
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$uniqueSuffix = "$Environment-$timestamp"
$shortSuffix = "$Environment" + (Get-Date -Format "MMddHHmm")
$redisName = "wanc-redis-$uniqueSuffix"
$appServiceName = "wanc-app-$uniqueSuffix"
$appServicePlanName = "wanc-plan-$uniqueSuffix"
$containerRegistryName = "wancregistry" + ($uniqueSuffix -replace '-', '')
$signalRName = "wanc-signalr-$uniqueSuffix"
$keyVaultName = "wanc-kv-$shortSuffix"

# Function to check if resource exists
function Test-AzureResource {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$ResourceGroup
    )
    
    try {
        $result = az resource show --name $ResourceName --resource-group $ResourceGroup --resource-type $ResourceType 2>$null
        return $result -ne $null
    }
    catch {
        return $false
    }
}

# Function to check if Key Vault secret exists
function Test-KeyVaultSecret {
    param(
        [string]$VaultName,
        [string]$SecretName
    )
    
    try {
        $result = az keyvault secret show --vault-name $VaultName --name $SecretName 2>$null
        return $result -ne $null
    }
    catch {
        return $false
    }
}

# Check if resource group exists
Write-Host "`nChecking Resource Group..." -ForegroundColor Cyan
$resourceGroupExists = az group show --name $ResourceGroupName 2>$null
if (-not $resourceGroupExists) {
    Write-Host "Creating Resource Group..." -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location
} else {
    Write-Host "Resource Group already exists" -ForegroundColor Green
}

# Check and create Key Vault
Write-Host "`nChecking Key Vault..." -ForegroundColor Cyan
$keyVaultExists = Test-AzureResource -ResourceType "Microsoft.KeyVault/vaults" -ResourceName $keyVaultName -ResourceGroup $ResourceGroupName
if (-not $keyVaultExists) {
    Write-Host "Creating Key Vault..." -ForegroundColor Yellow
    az keyvault create --name $keyVaultName --resource-group $ResourceGroupName --location $Location --sku standard
    
    # Get current user object ID for Key Vault access
    $currentUser = az ad signed-in-user show | ConvertFrom-Json
    az keyvault set-policy --name $keyVaultName --object-id $currentUser.id --secret-permissions get set list delete
} else {
    Write-Host "Key Vault already exists" -ForegroundColor Green
}

# Check and create App Service Plan
Write-Host "`nChecking App Service Plan..." -ForegroundColor Cyan
$appServicePlanExists = Test-AzureResource -ResourceType "Microsoft.Web/serverfarms" -ResourceName $appServicePlanName -ResourceGroup $ResourceGroupName
if (-not $appServicePlanExists) {
    Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
    az appservice plan create --name $appServicePlanName --resource-group $ResourceGroupName --location $Location --sku $AppServicePlanSku --is-linux
} else {
    Write-Host "App Service Plan already exists" -ForegroundColor Green
}

# Check and create Container Registry (if not skipped)
if (-not $SkipContainerRegistry) {
    Write-Host "`nChecking Container Registry..." -ForegroundColor Cyan
    $acrExists = Test-AzureResource -ResourceType "Microsoft.ContainerRegistry/registries" -ResourceName $containerRegistryName -ResourceGroup $ResourceGroupName
    if (-not $acrExists) {
        Write-Host "Creating Container Registry..." -ForegroundColor Yellow
        az acr create --name $containerRegistryName --resource-group $ResourceGroupName --location $Location --sku Basic --admin-enabled true
    } else {
        Write-Host "Container Registry already exists" -ForegroundColor Green
    }
}

# Check and create Redis Cache
Write-Host "`nChecking Redis Cache..." -ForegroundColor Cyan
$redisExists = Test-AzureResource -ResourceType "Microsoft.Cache/Redis" -ResourceName $redisName -ResourceGroup $ResourceGroupName
if (-not $redisExists) {
    Write-Host "Creating Redis Cache..." -ForegroundColor Yellow
    az redis create --name $redisName --resource-group $ResourceGroupName --location $Location --sku Basic --vm-size C0
} else {
    Write-Host "Redis Cache already exists" -ForegroundColor Green
}

# Check and create SignalR Service (if not skipped)
if (-not $SkipSignalR) {
    Write-Host "`nChecking SignalR Service..." -ForegroundColor Cyan
    $signalRExists = Test-AzureResource -ResourceType "Microsoft.SignalRService/SignalR" -ResourceName $signalRName -ResourceGroup $ResourceGroupName
    if (-not $signalRExists) {
        Write-Host "Creating SignalR Service..." -ForegroundColor Yellow
        az signalr create --name $signalRName --resource-group $ResourceGroupName --location $Location --sku Free_F1
    } else {
        Write-Host "SignalR Service already exists" -ForegroundColor Green
    }
}

# Check and create App Service
Write-Host "`nChecking App Service..." -ForegroundColor Cyan
$appServiceExists = Test-AzureResource -ResourceType "Microsoft.Web/sites" -ResourceName $appServiceName -ResourceGroup $ResourceGroupName
if (-not $appServiceExists) {
    Write-Host "Creating App Service..." -ForegroundColor Yellow
    az webapp create --name $appServiceName --resource-group $ResourceGroupName --plan $appServicePlanName --deployment-local-git
} else {
    Write-Host "App Service already exists" -ForegroundColor Green
}

# Configure App Service settings
Write-Host "`nConfiguring App Service settings..." -ForegroundColor Cyan

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

# Apply app settings
foreach ($setting in $appSettings.GetEnumerator()) {
    az webapp config appsettings set --name $appServiceName --resource-group $ResourceGroupName --settings "$($setting.Key)=$($setting.Value)"
}

# Enable managed identity for Key Vault access
Write-Host "Enabling managed identity..." -ForegroundColor Cyan
az webapp identity assign --name $appServiceName --resource-group $ResourceGroupName

# Get managed identity principal ID
$identityPrincipalId = az webapp identity show --name $appServiceName --resource-group $ResourceGroupName --query principalId --output tsv

# Grant Key Vault access to managed identity
az keyvault set-policy --name $keyVaultName --object-id $identityPrincipalId --secret-permissions get list

# Add secrets to Key Vault
Write-Host "`nAdding secrets to Key Vault..." -ForegroundColor Cyan

# Redis connection string
if ($redisExists -or (Test-AzureResource -ResourceType "Microsoft.Cache/Redis" -ResourceName $redisName -ResourceGroup $ResourceGroupName)) {
    if (-not (Test-KeyVaultSecret -VaultName $keyVaultName -SecretName "RedisConnectionString")) {
        Write-Host "Adding Redis connection string to Key Vault..." -ForegroundColor Yellow
        $redisKeys = az redis list-keys --name $redisName --resource-group $ResourceGroupName | ConvertFrom-Json
        $redisHost = az redis show --name $redisName --resource-group $ResourceGroupName --query hostName --output tsv
        $redisPort = az redis show --name $redisName --resource-group $ResourceGroupName --query port --output tsv
        $redisConnectionString = "$redisHost`:$redisPort,password=$($redisKeys.primaryKey),ssl=True,abortConnect=False"
        
        az keyvault secret set --vault-name $keyVaultName --name "RedisConnectionString" --value $redisConnectionString
        
        # Also add to App Service settings
        az webapp config appsettings set --name $appServiceName --resource-group $ResourceGroupName --settings "Redis:ConnectionString=$redisConnectionString"
    } else {
        Write-Host "Redis connection string already exists in Key Vault" -ForegroundColor Green
    }
}

# SignalR connection string
if (-not $SkipSignalR) {
    if ($signalRExists -or (Test-AzureResource -ResourceType "Microsoft.SignalRService/SignalR" -ResourceName $signalRName -ResourceGroup $ResourceGroupName)) {
        if (-not (Test-KeyVaultSecret -VaultName $keyVaultName -SecretName "SignalRConnectionString")) {
            Write-Host "Adding SignalR connection string to Key Vault..." -ForegroundColor Yellow
            $signalRKeys = az signalr key list --name $signalRName --resource-group $ResourceGroupName | ConvertFrom-Json
            $signalRHost = az signalr show --name $signalRName --resource-group $ResourceGroupName --query hostName --output tsv
            $signalRConnectionString = "Endpoint=https://$signalRHost;AccessKey=$($signalRKeys.primaryKey);Version=1.0;"
            
            az keyvault secret set --vault-name $keyVaultName --name "SignalRConnectionString" --value $signalRConnectionString
            
            # Also add to App Service settings
            az webapp config appsettings set --name $appServiceName --resource-group $ResourceGroupName --settings "Azure:SignalR:ConnectionString=$signalRConnectionString"
        } else {
            Write-Host "SignalR connection string already exists in Key Vault" -ForegroundColor Green
        }
    }
}

# Container Registry credentials
if (-not $SkipContainerRegistry) {
    if ($acrExists -or (Test-AzureResource -ResourceType "Microsoft.ContainerRegistry/registries" -ResourceName $containerRegistryName -ResourceGroup $ResourceGroupName)) {
        if (-not (Test-KeyVaultSecret -VaultName $keyVaultName -SecretName "AcrUsername")) {
            Write-Host "Adding ACR credentials to Key Vault..." -ForegroundColor Yellow
            $acrCredentials = az acr credential show --name $containerRegistryName | ConvertFrom-Json
            $acrLoginServer = az acr show --name $containerRegistryName --query loginServer --output tsv
            
            az keyvault secret set --vault-name $keyVaultName --name "AcrUsername" --value $acrCredentials.username
            az keyvault secret set --vault-name $keyVaultName --name "AcrPassword" --value $acrCredentials.passwords[0].value
            az keyvault secret set --vault-name $keyVaultName --name "AcrLoginServer" --value $acrLoginServer
        } else {
            Write-Host "ACR credentials already exist in Key Vault" -ForegroundColor Green
        }
    }
}

# Configure container deployment if ACR exists
if (-not $SkipContainerRegistry) {
    if ($acrExists -or (Test-AzureResource -ResourceType "Microsoft.ContainerRegistry/registries" -ResourceName $containerRegistryName -ResourceGroup $ResourceGroupName)) {
        Write-Host "Configuring container deployment..." -ForegroundColor Cyan
        $acrLoginServer = az acr show --name $containerRegistryName --query loginServer --output tsv
        az webapp config container set --name $appServiceName --resource-group $ResourceGroupName --docker-custom-image-name "$acrLoginServer/wanc-tracker:latest"
    }
}

# Output deployment summary
Write-Host "`nDeployment Completion Summary:" -ForegroundColor Green
Write-Host "`nResources Status:" -ForegroundColor Yellow
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
    $acrLoginServer = az acr show --name $containerRegistryName --query loginServer --output tsv
    Write-Host "   docker build -t $acrLoginServer/wanc-tracker ."
    Write-Host "   az acr login --name $containerRegistryName"
    Write-Host "   docker push $acrLoginServer/wanc-tracker:latest"
}
Write-Host "2. Deploy your application:"
Write-Host "   az webapp restart --name $appServiceName --resource-group $ResourceGroupName"
Write-Host "3. Access your application:"
Write-Host "   https://$appServiceName.azurewebsites.net"

Write-Host "`nDeployment completion finished!" -ForegroundColor Green
