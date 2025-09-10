# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "wanc-kv-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]

    certificate_permissions = [
      "Create",
      "Delete",
      "Get",
      "Import",
      "List",
      "Update"
    ]
  }

  tags = local.common_tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "wanc-plan-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = local.common_tags
}

# Container Registry
resource "azurerm_container_registry" "main" {
  count               = var.deploy_container_registry ? 1 : 0
  name                = "wancregistry${replace(local.unique_suffix, "-", "")}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"
  admin_enabled       = true

  tags = local.common_tags
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "wanc-redis-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = var.redis_cache_capacity
  family              = var.redis_cache_family
  sku_name            = var.redis_cache_sku
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = local.common_tags
}

# Azure SignalR Service
resource "azurerm_signalr_service" "main" {
  count               = var.deploy_signalr ? 1 : 0
  name                = "wanc-signalr-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    name     = var.signalr_sku
    capacity = var.signalr_capacity
  }

  tags = local.common_tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "wanc-app-${local.unique_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image     = "nginx:alpine"
      docker_image_tag = "latest"
    }
    
    always_on = var.app_service_plan_sku != "F1" ? true : false
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_ENABLE_CI"                    = "true"
    "WEBSITES_PORT"                       = "8080"
    "ASPNETCORE_ENVIRONMENT"              = var.environment
    "KeyVault:VaultUri"                   = azurerm_key_vault.main.vault_uri
    "Redis:ConnectionString"              = azurerm_redis_cache.main.primary_connection_string
    "Azure:SignalR:ConnectionString"      = var.deploy_signalr ? azurerm_signalr_service.main[0].primary_connection_string : ""
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Key Vault Access Policy for App Service
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = azurerm_linux_web_app.main.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.main.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Container Registry Access for App Service (if ACR is deployed)
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.deploy_container_registry ? 1 : 0
  scope                = azurerm_container_registry.main[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}
