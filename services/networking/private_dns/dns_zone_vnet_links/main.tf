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
  name      = var.private_dns_zone_name
  parent_id = var.private_dns_zone_id

  body = jsonencode({
    properties = {
      registrationEnabled = try(var.registration_enabled, false)
      virtualNetwork = {
        id = var.virtual_network_id
      }
    }
  })

  tags = try(var.tags, {})
}
