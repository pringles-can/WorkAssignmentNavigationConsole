terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy         = true
      recover_soft_deleted_keys                  = true
      purge_soft_deleted_secrets_on_destroy      = true
      recover_soft_deleted_secrets               = true
      purge_soft_deleted_certificates_on_destroy = true
      recover_soft_deleted_certificates          = true
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  unique_suffix = "${var.environment}-${substr(md5(azurerm_resource_group.main.id), 0, 8)}"
  
  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    Project     = "WorkAssignmentNavigationConsole"
    ManagedBy   = "Terraform"
  }
}
