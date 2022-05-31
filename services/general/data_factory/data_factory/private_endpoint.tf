module "private_endpoint" {
  source              = "../../../networking/private_endpoint"
  for_each            = try(var.settings.private_endpoints, {})
  tags                = var.tags
  location            = try(each.value.location, var.global_settings.location, null)
  settings            = each.value
  name                = "${var.global_settings.name_clean}${each.value.name}"
  resource_group_name = try(each.value.resource_group_name, var.combined_objects_core.resource_groups[try(each.value.resource_group.key, each.value.resource_group_key)].name)
  private_dns         = var.combined_objects_core.private_dns_zones
  resource_id         = azurerm_data_factory.df.id
  subnet_id           = can(each.value.subnet_id) ? each.value.subnet_id : var.combined_objects_core.virtual_subnets[each.value.subnet_key].id
}
