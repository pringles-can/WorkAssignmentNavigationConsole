# Work Assignment Navigation Console - Terraform Infrastructure

This directory contains Terraform configuration files to deploy and manage all Azure resources for the Work Assignment Navigation Console (WANC) project.

## Prerequisites

1. **Azure CLI** - Install and configure with your Azure subscription
2. **Terraform** - Version 1.0 or higher
3. **Azure Subscription** - With appropriate permissions to create resources

## Quick Start

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Initialize Terraform**:
   ```bash
   cd azure/terraform
   terraform init
   ```

3. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

4. **Plan Deployment**:
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

## Configuration

### Variables

The following variables can be configured in `terraform.tfvars`:

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `resource_group_name` | Name of the resource group | `wanc-tracker-dev` | Any valid RG name |
| `location` | Azure region for resources | `East US` | Any valid Azure region |
| `environment` | Environment name | `dev` | `dev`, `staging`, `prod` |
| `app_service_plan_sku` | App Service Plan SKU | `B1` | `F1`, `B1`, `B2`, `B3`, `S1`, `S2`, `S3`, `P1`, `P2`, `P3`, `P1V2`, `P2V2`, `P3V2`, `P1V3`, `P2V3`, `P3V3` |
| `redis_cache_sku` | Redis Cache SKU | `Basic` | `Basic`, `Standard`, `Premium` |
| `redis_cache_family` | Redis Cache family | `C` | `C` (Basic/Standard), `P` (Premium) |
| `redis_cache_capacity` | Redis Cache capacity | `0` | `0-6` (varies by SKU) |
| `signalr_sku` | SignalR Service SKU | `Free_F1` | `Free_F1`, `Standard_S1` |
| `signalr_capacity` | SignalR Service capacity | `1` | `1-100` (for Standard_S1) |
| `deploy_signalr` | Deploy SignalR Service | `true` | `true`, `false` |
| `deploy_container_registry` | Deploy Container Registry | `true` | `true`, `false` |

## Resources Created

This Terraform configuration creates the following Azure resources:

1. **Resource Group** - Container for all resources
2. **Key Vault** - For storing secrets and configuration
3. **App Service Plan** - Linux-based hosting plan
4. **App Service** - Container-based web application
5. **Redis Cache** - For caching and session storage
6. **Azure SignalR Service** - For real-time communication (optional)
7. **Container Registry** - For storing Docker images (optional)

## Outputs

After deployment, Terraform provides the following outputs:

- `app_service_url` - URL to access the deployed application
- `redis_cache_hostname` - Redis connection details
- `key_vault_uri` - Key Vault URI for configuration
- `container_registry_login_server` - ACR login server (if deployed)
- `signalr_hostname` - SignalR service hostname (if deployed)

## Security

- All resources are tagged with environment and project information
- Key Vault has soft delete enabled with 7-day retention
- App Service uses managed identity for secure access to other resources
- Redis Cache is configured with SSL-only connections
- Access policies are automatically configured for the App Service to access Key Vault

## Cost Optimization

- Default configuration uses cost-effective SKUs (B1 for App Service, Basic for Redis, Free for SignalR)
- Resources can be scaled up by modifying the SKU variables
- Optional resources (SignalR, Container Registry) can be disabled to reduce costs

## Environment-Specific Deployments

For different environments, create separate `.tfvars` files:

- `dev.tfvars` - Development environment
- `staging.tfvars` - Staging environment  
- `prod.tfvars` - Production environment

Deploy with:
```bash
terraform apply -var-file="dev.tfvars"
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will permanently delete all resources and data. Make sure to backup any important data first.

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your Azure account has Contributor or Owner role on the subscription
2. **Resource Name Conflicts**: Azure resource names must be globally unique. The configuration uses a unique suffix to avoid conflicts
3. **SKU Availability**: Some SKUs may not be available in all regions. Check Azure documentation for availability

### Useful Commands

```bash
# Check current state
terraform show

# List all resources
terraform state list

# Import existing resources (if needed)
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/...

# Validate configuration
terraform validate

# Format configuration files
terraform fmt
```
