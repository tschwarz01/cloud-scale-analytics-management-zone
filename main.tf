terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.7.0"
    }
  }
  required_version = ">= 0.15"
  experiments      = [module_variable_optional_attrs]
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    template_deployment {
      delete_nested_items_during_deletion = true
    }
  }
}
data "azurerm_client_config" "default" {}
data "azuread_client_config" "current" {}

module "core" {
  source          = "./modules/core"
  global_settings = local.global_settings
  module_settings = local.core_module_settings
  tags            = local.global_settings.tags
  # diagnostics = {
  #   diagnostic_log_analytics = var.diagnostic_log_analytics
  #   diagnostics_destinations = var.diagnostics_destinations
  #   diagnostics_definition   = local.diagnostics_definition
  # }
}
module "consumption" {
  source                = "./modules/consumption"
  global_settings       = local.global_settings
  module_settings       = local.consumption_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}
module "governance" {
  source                = "./modules/governance"
  global_settings       = local.global_settings
  module_settings       = local.governance_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}
module "integration" {
  source                = "./modules/integration"
  global_settings       = local.global_settings
  module_settings       = local.integration_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}
