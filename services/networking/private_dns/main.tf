module "zones" {
  for_each = { for key, value in var.private_dns_zones : key => value if lookup(value, "is_remote", false) != true }
  source   = "./private_dns_zones"

  global_settings     = var.global_settings
  name                = each.value.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

module "dns_zone_vnet_links" {
  for_each = var.private_dns_zones
  source   = "./dns_zone_vnet_links"

  global_settings       = var.global_settings
  private_dns_zone_name = module.zones[each.value.name].name #coalesce(module.zones[each.value.name].name, each.value.name)
  private_dns_zone_id   = module.zones[each.value.name].id   #coalesce(module.zones[each.value.name].id, each.value.id)
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = lookup(each.value, "registration_enabled", false)
  tags                  = var.tags
}
