terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 0.2.0"
    }
  }
}

resource "azapi_resource" "virtualNetworkLinks" {
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01"
  location  = "global"
  name      = "${var.global_settings.name}-${var.private_dns_zone_name}"
  parent_id = var.private_dns_zone_id

  body = jsonencode({
    properties = {
      registrationEnabled = coalesce(var.registration_enabled, false)
      virtualNetwork = {
        id = var.virtual_network_id
      }
    }
  })

  tags = var.tags
}
