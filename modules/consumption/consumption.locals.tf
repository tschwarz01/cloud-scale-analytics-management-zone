locals {

  shared_image_galleries = {
    gallery1 = {
      name               = "imggallery"
      resource_group_key = "consumption"
      location           = var.global_settings.location
      description        = "This is a shared image gallery"
    }
  }
  azure_container_registries = {
    acr1 = {
      name                          = "acr"
      resource_group_key            = "consumption"
      location                      = var.global_settings.location
      sku                           = "Premium"
      quarantine_policy_enabled     = true
      public_network_access_enabled = false
      retention_policy = {
        days    = 7
        enabled = true
      }
      diagnostic_profiles = {
        operations = {
          name             = "acr_logs"
          definition_key   = "azure_container_registry"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }
    }
  }
  synapse_privatelink_hubs = {
    plh1 = {
      name               = "synplh"
      resource_group_key = "consumption"
      location           = var.global_settings.location
    }
  }
  private_endpoints = {
    acr = {
      resource_id        = azurerm_container_registry.acr["acr1"].id
      name               = "dmlz"
      subnet_key         = "private_endpoints"
      resource_group_key = "consumption"
      location           = var.global_settings.location
      private_service_connection = {
        name                 = "acr0031"
        is_manual_connection = false
        subresource_names    = ["registry"]
      }
      private_dns = {
        zone_group_name = "privatelink.azurecr.io"
        keys            = ["privatelink.azurecr.io"]
      }
    }
    plhpe1 = {
      resource_id        = azurerm_synapse_private_link_hub.plh["plh1"].id
      name               = "synplh"
      resource_group_key = "consumption"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "syn-plh"
        is_manual_connection = false
        subresource_names    = ["web"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.azuresynapse.net"]
      }
    }
  }
}
