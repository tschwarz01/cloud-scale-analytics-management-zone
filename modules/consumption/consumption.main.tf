
resource "azurerm_shared_image_gallery" "sig" {
  for_each            = local.shared_image_galleries
  name                = "${var.global_settings.name_clean}${each.value.name}"
  resource_group_name = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location            = each.value.location
  description         = try(each.value.description, null)
  tags                = var.tags
}


resource "azurerm_container_registry" "acr" {
  for_each                      = local.azure_container_registries
  name                          = "${var.global_settings.name_clean}${each.value.name}"
  resource_group_name           = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location                      = each.value.location
  sku                           = "Premium"
  admin_enabled                 = try(each.value.admin_enabled, false)
  quarantine_policy_enabled     = try(each.value.quarantine_policy_enabled, false)
  public_network_access_enabled = try(each.value.public_network_access_enabled, true)
  identity {
    type = "SystemAssigned"
  }
  dynamic "retention_policy" {
    for_each = try(each.value.retention_policy, null) == null ? [] : [each.value.retention_policy]
    content {
      days    = lookup(retention_policy.value, "days", null)
      enabled = lookup(retention_policy.value, "enabled", true)
    }
  }
}


module "diagnostics" {
  source            = "../../services/logmon/diagnostics"
  for_each          = azurerm_container_registry.acr
  resource_id       = each.value.id
  resource_location = each.value.location
  diagnostics       = var.combined_objects_core.diagnostics
  profiles          = local.azure_container_registries[each.key].diagnostic_profiles
}


resource "azurerm_synapse_private_link_hub" "plh" {
  for_each            = local.synapse_privatelink_hubs
  name                = "${var.global_settings.name_clean}${each.value.name}"
  resource_group_name = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location            = each.value.location
}


module "private_endpoints" {
  depends_on          = [azurerm_container_registry.acr, azurerm_synapse_private_link_hub.plh]
  source              = "../../services/networking/private_endpoint"
  for_each            = local.private_endpoints
  tags                = var.global_settings.tags
  location            = try(each.value.location, var.global_settings.location, null)
  settings            = each.value
  name                = "${var.global_settings.name_clean}${each.value.name}"
  resource_group_name = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  private_dns         = var.combined_objects_core.private_dns_zones
  resource_id         = each.value.resource_id
  subnet_id           = var.combined_objects_core.virtual_subnets[each.value.subnet_key].id
}
