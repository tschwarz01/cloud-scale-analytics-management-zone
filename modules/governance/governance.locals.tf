locals {

  purview_accounts = {
    pva1 = {
      name                        = "pva1"
      location                    = var.global_settings.location
      resource_group_key          = "governance"
      public_network_enabled      = false
      managed_resource_group_name = "managed-purview"
    }
  }

  private_endpoints = {
    account = {
      resource_id        = azurerm_purview_account.pva["pva1"].id
      name               = "account"
      resource_group_key = "governance"
      location           = var.global_settings.location
      subnet_id          = var.combined_objects_core.virtual_subnets["private_endpoints"].id

      private_service_connection = {
        name                 = "account"
        is_manual_connection = false
        subresource_names    = ["account"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.purview.azure.com"]
      }
    }

    portal = {
      resource_id        = azurerm_purview_account.pva["pva1"].id
      name               = "portal"
      resource_group_key = "governance"
      location           = var.global_settings.location
      subnet_id          = var.combined_objects_core.virtual_subnets["private_endpoints"].id

      private_service_connection = {
        name                 = "portal"
        is_manual_connection = false
        subresource_names    = ["portal"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.purviewstudio.azure.com"]
      }
    }

    blob = {
      resource_id        = azurerm_purview_account.pva["pva1"].managed_resources[0].storage_account_id
      name               = "blob"
      resource_group_key = "governance"
      location           = var.global_settings.location
      subnet_id          = var.combined_objects_core.virtual_subnets["private_endpoints"].id

      private_service_connection = {
        name                 = "blob"
        is_manual_connection = false
        subresource_names    = ["blob"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.blob.core.windows.net"]
      }
    }

    queue = {
      resource_id        = azurerm_purview_account.pva["pva1"].managed_resources[0].storage_account_id
      name               = "queue"
      resource_group_key = "governance"
      location           = var.global_settings.location
      subnet_id          = var.combined_objects_core.virtual_subnets["private_endpoints"].id

      private_service_connection = {
        name                 = "queue"
        is_manual_connection = false
        subresource_names    = ["queue"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.queue.core.windows.net"]
      }
    }

    eventhub = {
      resource_id        = azurerm_purview_account.pva["pva1"].managed_resources[0].event_hub_namespace_id
      name               = "eventhub"
      resource_group_key = "governance"
      location           = var.global_settings.location
      subnet_id          = var.combined_objects_core.virtual_subnets["private_endpoints"].id

      private_service_connection = {
        name                 = "eventhub"
        is_manual_connection = false
        subresource_names    = ["namespace"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.servicebus.windows.net"]
      }
    }

  }


  keyvaults = {
    governance = {
      name                      = "governance2229"
      location                  = var.global_settings.location
      resource_group_key        = "governance"
      sku_name                  = "standard"
      enable_rbac_authorization = true
      soft_delete_enabled       = true
      purge_protection_enabled  = false

      diagnostic_profiles = {
        central_logs_region1 = {
          definition_key   = "azure_key_vault"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }

      private_endpoints = {
        vault = {
          name               = "kvgov"
          resource_group_key = "governance"
          location           = var.global_settings.location
          vnet_key           = "vnet"
          subnet_key         = "private_endpoints"

          private_service_connection = {
            name                 = "kvgov"
            is_manual_connection = false
            subresource_names    = ["vault"]
          }

          private_dns = {
            zone_group_name = "default"
            keys            = ["privatelink.vaultcore.azure.net"]
          }
        }
      }
    }
  }


  role_assignments = {
    pv_kv = {
      scope                = module.keyvault["governance"].id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = azurerm_purview_account.pva["pva1"].identity[0].principal_id
    }
  }

}

