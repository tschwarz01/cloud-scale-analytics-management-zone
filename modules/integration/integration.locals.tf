locals {
  keyvaults = {
    integration = {
      name                      = "integration41"
      location                  = var.global_settings.location
      resource_group_key        = "integration"
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
          name               = "kvint"
          resource_group_key = "integration"
          location           = var.global_settings.location
          vnet_key           = "vnet"
          subnet_key         = "private_endpoints"

          private_service_connection = {
            name                 = "kvint"
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
    kvint = {
      scope                = module.keyvault["integration"].id
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = var.global_settings.client_config.object_id
    }
  }


  data_factory = {
    df1 = {
      name                            = "adf-integration21tws"
      resource_group_name             = var.combined_objects_core.resource_groups["integration"].name
      managed_virtual_network_enabled = true
      enable_system_msi               = true

      self_hosted_integration_runtimes = {
        dfirsh1 = {
          name = "adfsharedshir21"
          resource_group = {
            key = "integration"
          }
          data_factory = {
            key = "df1"
          }
        }
      }

      diagnostic_profiles = {
        central_logs_region1 = {
          definition_key   = "azure_data_factory"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }

      private_endpoints = {
        df1-factory = {
          name               = "adf-int-acct"
          subnet_key         = "private_endpoints"
          resource_group_key = "integration"

          private_service_connection = {
            name                 = "adf-int-acct"
            is_manual_connection = false
            subresource_names    = ["dataFactory"]
          }

          private_dns = {
            zone_group_name = "privatelink.datafactory.azure.net"
            keys            = ["privatelink.datafactory.azure.net"]
          }
        }

        df1-portal = {
          name               = "adf-int-portal"
          subnet_key         = "private_endpoints"
          resource_group_key = "integration"

          private_service_connection = {
            name                 = "adf-int-portal"
            is_manual_connection = false
            subresource_names    = ["portal"]
          }

          private_dns = {
            zone_group_name = "privatelink.adf.azure.com"
            keys            = ["privatelink.adf.azure.com"]
          }
        }
      }
    }
  }


  vmss_self_hosted_integration_runtime = {
    vmss01 = {
      data_factory_self_hosted_runtime_authorization_script = var.module_settings.data_factory_self_hosted_runtime_authorization_script
      resource_group_key                                    = "integration"
      data_factory_key                                      = "df1"
      integration_runtime_key                               = "dfirsh1"
      vnet_key                                              = "vnet"
      subnet_key                                            = "services"
      keyvault_key                                          = "integration"
      boot_diagnostics_storage_account_key                  = "bootdiag1"

      vmss_settings = {
        windows = {
          provision_vm_agent = true
          admin_username     = try(var.module_settings.vmss_admin_username, "adminuser")
          name               = "shir"
          sku                = "Standard_D4d_v4"
          priority           = "Spot"
          eviction_policy    = "Deallocate"
          instances          = 2
        }
      }
    }
  }
}
