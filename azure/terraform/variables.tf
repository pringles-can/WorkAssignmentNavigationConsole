variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "wanc-tracker-dev"
}

variable "location" {
  description = "Location for all resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_service_plan_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "F1"
  
  validation {
    condition     = contains(["F1", "B1", "B2", "B3", "S1", "S2", "S3", "P1", "P2", "P3", "P1V2", "P2V2", "P3V2", "P1V3", "P2V3", "P3V3"], var.app_service_plan_sku)
    error_message = "App Service Plan SKU must be a valid SKU."
  }
}

variable "redis_cache_sku" {
  description = "Redis Cache SKU"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_cache_sku)
    error_message = "Redis Cache SKU must be one of: Basic, Standard, Premium."
  }
}

variable "redis_cache_family" {
  description = "Redis Cache family (C for Basic/Standard, P for Premium)"
  type        = string
  default     = "C"
  
  validation {
    condition     = contains(["C", "P"], var.redis_cache_family)
    error_message = "Redis Cache family must be C or P."
  }
}

variable "redis_cache_capacity" {
  description = "Redis Cache capacity"
  type        = number
  default     = 0
  
  validation {
    condition     = var.redis_cache_capacity >= 0 && var.redis_cache_capacity <= 6
    error_message = "Redis Cache capacity must be between 0 and 6."
  }
}

variable "signalr_sku" {
  description = "Azure SignalR Service SKU"
  type        = string
  default     = "Free_F1"
  
  validation {
    condition     = contains(["Free_F1", "Standard_S1"], var.signalr_sku)
    error_message = "SignalR SKU must be one of: Free_F1, Standard_S1."
  }
}

variable "signalr_capacity" {
  description = "Azure SignalR Service capacity"
  type        = number
  default     = 1
  
  validation {
    condition     = var.signalr_capacity >= 1 && var.signalr_capacity <= 100
    error_message = "SignalR capacity must be between 1 and 100."
  }
}

variable "deploy_signalr" {
  description = "Whether to deploy Azure SignalR Service"
  type        = bool
  default     = true
}

variable "deploy_container_registry" {
  description = "Whether to deploy Azure Container Registry"
  type        = bool
  default     = true
}
