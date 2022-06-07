resource "azurerm_private_endpoint" "pep" {
  name                = var.settings.name
  location            = try(var.location, var.settings.location)
  resource_group_name = try(var.resource_group_name, var.settings.resource_group_name)
  subnet_id           = try(var.subnet_id, var.settings.subnet_id)
  tags                = var.tags

  private_service_connection {
    name                           = var.settings.private_service_connection.name
    private_connection_resource_id = try(var.settings.resource_id, var.resource_id, null)
    is_manual_connection           = try(var.settings.private_service_connection.is_manual_connection, false)
    subresource_names              = var.settings.private_service_connection.subresource_names
    request_message                = try(var.settings.private_service_connection.request_message, null)
  }

  private_dns_zone_group {
    name = try(var.settings.private_dns.zone_group_name, "default")

    private_dns_zone_ids = concat(
      flatten([
        for key in var.private_dns.keys : [
          try(var.private_dns_zones[key], [])
        ]
        ]
      )
    )
    # private_dns_zone_ids = [
    #   var.private_dns[var.settings.private_dns.keys[0]]
    # ]
  }
}
