resource "azurerm_private_endpoint" "pep" {
  name                = can(var.name) ? var.name : lookup(var.settings, "name", null)
  location            = can(var.location) ? var.location : lookup(var.settings, "location", null)
  resource_group_name = can(var.resource_group_name) ? var.resource_group_name : lookup(var.settings, "resource_group_name", null)
  subnet_id           = can(var.subnet_id) ? var.subnet_id : lookup(var.settings, "subnet_id", null)
  tags                = var.tags

  private_service_connection {
    name                           = coalesce(var.private_service_connection.name, var.settings.private_service_connection.name)
    private_connection_resource_id = can(var.resource_id) ? var.resource_id : lookup(var.settings, "resource_id", null)
    is_manual_connection           = coalesce(var.private_service_connection.is_manual_connection, var.settings.private_service_connection.is_manual_connection, false)
    subresource_names              = coalesce(var.private_service_connection.subresource_names, var.settings.private_service_connection.subresource_names)
    request_message                = can(var.private_service_connection.request_message) ? var.private_service_connection.request_message : null
  }

  private_dns_zone_group {
    name = coalesce(var.private_dns.zone_group_name, var.settings.private_dns.zone_group_name, "default")

    private_dns_zone_ids = concat(
      flatten([
        for key in var.private_dns.keys : [
          var.private_dns_zones[key]
        ]
        ]
      )
    )

  }
}
