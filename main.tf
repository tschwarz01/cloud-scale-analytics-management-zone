terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.10.0"
    }
  }

  backend "azurerm" {
    subscription_id      = "47f7e6d7-0e52-4394-92cb-5f106bbc647f"
    tenant_id            = "72f988bf-86f1-41af-91ab-2d7cd011db47"
    resource_group_name  = "rg-data-management-zone-terraform"
    storage_account_name = "stgcafcsaterraformstate"
    container_name       = "caf-csa-management-zone"
    key                  = "dmlz.terraform.tfstate"
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
data "azurerm_subscription" "current" {}


module "core" {
  source          = "./modules/core"
  global_settings = local.global_settings
  module_settings = local.core_module_settings
  tags            = local.global_settings.tags
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


module "automation" {
  source                = "./modules/automation"
  global_settings       = local.global_settings
  module_settings       = local.automation_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}
