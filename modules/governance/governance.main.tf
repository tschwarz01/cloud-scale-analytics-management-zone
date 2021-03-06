resource "azurerm_purview_account" "pva" {
  for_each                    = local.purview_accounts
  name                        = "${var.global_settings.name}-${each.value.name}"
  location                    = each.value.location
  resource_group_name         = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  public_network_enabled      = lookup(each.value, "public_network_enabled", true)
  managed_resource_group_name = lookup(each.value, "managed_resource_group_name", null)
  tags                        = var.tags
  identity {
    type = "SystemAssigned"
  }
}


module "keyvault" {
  source                = "../../services/general/keyvault/keyvault"
  for_each              = local.keyvaults
  name                  = "${var.global_settings.name}-${each.value.name}"
  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  combined_objects_core = var.combined_objects_core
  tags                  = var.tags
}


module "private_endpoints" {
  source   = "../../services/networking/private_endpoint"
  for_each = local.private_endpoints

  location                   = coalesce(each.value.location, var.global_settings.location)
  resource_group_name        = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  resource_id                = each.value.resource_id
  name                       = "${var.global_settings.name_clean}${each.value.name}"
  private_service_connection = each.value.private_service_connection
  subnet_id                  = coalesce(each.value.subnet_id, var.combined_objects_core.virtual_subnets["private_endpoints"].id)
  private_dns                = each.value.private_dns
  private_dns_zones          = var.combined_objects_core.private_dns_zones
  settings                   = each.value
  tags                       = var.tags
}


resource "azurerm_role_assignment" "role_assignment" {
  for_each             = local.role_assignments
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
