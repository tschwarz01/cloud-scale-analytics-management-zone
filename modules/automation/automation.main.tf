

resource "azurerm_cosmosdb_account" "acct" {
  for_each                      = local.cosmosdb_accounts
  name                          = "${var.global_settings.name}-${each.value.name}"
  location                      = var.global_settings.location
  resource_group_name           = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  offer_type                    = "Standard"
  enable_free_tier              = each.value.enable_free_tier
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = false
  enable_automatic_failover     = each.value.enable_automatic_failover
  tags                          = var.tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.global_settings.location
    failover_priority = 0
  }
}


resource "azurerm_cosmosdb_sql_database" "db" {
  for_each            = local.cosmosdb_databases
  name                = "${var.global_settings.name}-${each.value.name}"
  resource_group_name = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  account_name        = azurerm_cosmosdb_account.acct[each.value.cosmos_account_key].name
  throughput          = 400
}


module "private_endpoints" {
  source   = "../../services/networking/private_endpoint"
  for_each = local.private_endpoints

  location                   = coalesce(each.value.location, var.global_settings.location)
  resource_group_name        = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  resource_id                = each.value.resource_id
  name                       = "${var.global_settings.name_clean}${each.value.name}"
  private_service_connection = each.value.private_service_connection
  subnet_id                  = var.combined_objects_core.virtual_subnets[each.value.subnet_key].id
  private_dns                = each.value.private_dns
  private_dns_zones          = var.combined_objects_core.private_dns_zones
  settings                   = each.value
  tags                       = var.global_settings.tags
}

