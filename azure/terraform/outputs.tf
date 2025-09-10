output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "app_service_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "redis_cache_name" {
  description = "Name of the Redis Cache"
  value       = azurerm_redis_cache.main.name
}

output "redis_cache_hostname" {
  description = "Hostname of the Redis Cache"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_cache_port" {
  description = "Port of the Redis Cache"
  value       = azurerm_redis_cache.main.port
}

output "redis_cache_ssl_port" {
  description = "SSL port of the Redis Cache"
  value       = azurerm_redis_cache.main.ssl_port
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = var.deploy_container_registry ? azurerm_container_registry.main[0].name : null
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = var.deploy_container_registry ? azurerm_container_registry.main[0].login_server : null
}

output "container_registry_admin_username" {
  description = "Admin username of the Container Registry"
  value       = var.deploy_container_registry ? azurerm_container_registry.main[0].admin_username : null
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password of the Container Registry"
  value       = var.deploy_container_registry ? azurerm_container_registry.main[0].admin_password : null
  sensitive   = true
}

output "signalr_name" {
  description = "Name of the SignalR Service"
  value       = var.deploy_signalr ? azurerm_signalr_service.main[0].name : null
}

output "signalr_hostname" {
  description = "Hostname of the SignalR Service"
  value       = var.deploy_signalr ? azurerm_signalr_service.main[0].hostname : null
}

output "signalr_primary_connection_string" {
  description = "Primary connection string of the SignalR Service"
  value       = var.deploy_signalr ? azurerm_signalr_service.main[0].primary_connection_string : null
  sensitive   = true
}

output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "app_service_identity_tenant_id" {
  description = "Tenant ID of the App Service managed identity"
  value       = azurerm_linux_web_app.main.identity[0].tenant_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "unique_suffix" {
  description = "Unique suffix used for resource naming"
  value       = local.unique_suffix
}
