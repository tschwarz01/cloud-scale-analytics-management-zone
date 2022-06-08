
locals {

  cosmosdb_accounts = {
    automation = {
      name                      = "cosmos-automation"
      resource_group_key        = "automation"
      enable_free_tier          = var.module_settings.enable_free_tier
      enable_automatic_failover = false
    }
  }


  cosmosdb_databases = {
    automation = {
      name               = "cmosmos-automationdb"
      resource_group_key = "automation"
      cosmos_account_key = "automation"
    }
  }


  private_endpoints = {
    cosmos = {
      resource_id        = azurerm_cosmosdb_account.acct["automation"].id
      name               = "cosmos"
      subnet_key         = "private_endpoints"
      resource_group_key = "automation"
      location           = var.global_settings.location
      private_service_connection = {
        name                 = "cosmos"
        is_manual_connection = false
        subresource_names    = ["Sql"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.documents.azure.com"]
      }
    }
  }

}
