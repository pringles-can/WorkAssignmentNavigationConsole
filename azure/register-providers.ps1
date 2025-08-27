# Azure Resource Provider Registration Script
# This script registers all required resource providers for the WANC application

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = ""
)

Write-Host "Registering Azure Resource Providers..." -ForegroundColor Green

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

# Get subscription ID if not provided
if (-not $SubscriptionId) {
    $SubscriptionId = az account show --query id --output tsv
    Write-Host "Using subscription: $SubscriptionId" -ForegroundColor Yellow
}

# List of required resource providers
$providers = @(
    "Microsoft.KeyVault",
    "Microsoft.Web",
    "Microsoft.Cache",
    "Microsoft.SignalRService",
    "Microsoft.ContainerRegistry",
    "Microsoft.Storage",
    "Microsoft.Network",
    "Microsoft.Insights"
)

Write-Host "Registering resource providers..." -ForegroundColor Cyan

foreach ($provider in $providers) {
    Write-Host "Registering $provider..." -ForegroundColor Yellow
    
    # Check if provider is already registered
    $registrationState = az provider show --namespace $provider --query registrationState --output tsv 2>$null
    
    if ($registrationState -eq "Registered") {
        Write-Host "  $provider is already registered" -ForegroundColor Green
    } else {
        Write-Host "  Registering $provider..." -ForegroundColor Yellow
        az provider register --namespace $provider
        
        # Wait for registration to complete
        $maxAttempts = 30
        $attempt = 0
        
        do {
            Start-Sleep -Seconds 10
            $attempt++
            $registrationState = az provider show --namespace $provider --query registrationState --output tsv 2>$null
            Write-Host "    Attempt $attempt/$maxAttempts - Status: $registrationState" -ForegroundColor Gray
            
            if ($registrationState -eq "Registered") {
                Write-Host "  $provider registration completed" -ForegroundColor Green
                break
            }
        } while ($attempt -lt $maxAttempts)
        
        if ($registrationState -ne "Registered") {
            Write-Warning "  $provider registration may still be in progress. You can continue with deployment."
        }
    }
}

Write-Host "`nResource provider registration completed!" -ForegroundColor Green
Write-Host "You can now run the deployment script:" -ForegroundColor Yellow
Write-Host "  .\azure-deploy.ps1 -ResourceGroupName 'wanc-tracker-dev' -Environment 'dev'" -ForegroundColor Cyan
