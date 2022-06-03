terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 0.2.0"
    }
  }
}


resource "azurerm_resource_group" "rg" {
  for_each = local.resource_groups

  name     = "${var.global_settings.name}-${each.value.name}"
  location = each.value.location
  tags     = try(var.tags, {})
}


resource "azurerm_network_security_group" "nsg" {
  for_each = local.networking.network_security_groups

  name                = "${var.global_settings.name}-${each.value.name}"
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  location            = each.value.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = try(each.value.nsg, [])

    content {
      name                         = try(security_rule.value.name, null)
      priority                     = try(security_rule.value.priority, null)
      direction                    = try(security_rule.value.direction, null)
      access                       = try(security_rule.value.access, null)
      protocol                     = try(security_rule.value.protocol, null)
      source_port_range            = try(security_rule.value.source_port_range, null)
      source_port_ranges           = try(security_rule.value.source_port_ranges, null)
      destination_port_range       = try(security_rule.value.destination_port_range, null)
      destination_port_ranges      = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix        = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes      = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix   = try(security_rule.value.destination_address_prefix, null)
      destination_address_prefixes = try(security_rule.value.destination_address_prefixes, null)
    }
  }
}


resource "azurerm_virtual_network" "vnet" {
  for_each = local.networking.vnets

  name                = "${var.global_settings.name}-${each.value.vnet.name}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  address_space       = each.value.vnet.address_space
  tags                = var.tags
}


resource "azurerm_subnet" "snet" {
  for_each = local.networking.subnets

  name                 = "${var.global_settings.name}-${each.value.name}"
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr

  dynamic "delegation" {
    for_each = try(each.value.delegation, null) == null ? [] : [each.value.delegation]

    content {
      name = delegation.value["name"]

      service_delegation {
        name    = delegation.value["service_delegation"]
        actions = lookup(delegation.value, "actions", null)
      }
    }
  }
}


resource "azurerm_subnet" "ssnet" {
  for_each = local.networking.specialsubnets

  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr

  dynamic "delegation" {
    for_each = try(each.value.delegation, null) == null ? [] : [each.value.delegation]

    content {

      name = delegation.value["name"]

      service_delegation {
        name    = delegation.value["service_delegation"]
        actions = lookup(delegation.value, "actions", null)
      }
    }
  }
}


locals {
  combined_subnet_inputs = merge(try(local.networking.subnets, {}), try(local.networking.specialsubnets, {}))
  subnets                = merge(try(azurerm_subnet.snet, {}), try(azurerm_subnet.ssnet, {}), {})
}


resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = { for key, value in try(local.combined_subnet_inputs, {}) : key => value if can(value.nsg_key) == true }

  subnet_id                 = local.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_key].id
}


module "private_dns" {
  for_each = local.ddi.local_private_dns_zones
  source   = "../../services/networking/private_dns"

  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  global_settings     = var.global_settings
  virtual_network_id  = try(azurerm_virtual_network.vnet[try(each.key, each.value.vnet_key)].id, null)
  private_dns_zones   = each.value.private_dns_zones
  tags                = var.tags
}


module "remote_vnet_links" {
  for_each = local.ddi.remote_private_dns_zones
  source   = "../../services/networking/private_dns"

  global_settings    = var.global_settings
  virtual_network_id = try(azurerm_virtual_network.vnet[try(each.key, each.value.vnet_key)].id, null)
  private_dns_zones  = each.value.private_dns_zones
  tags               = var.tags
}


resource "azapi_resource" "virtualNetworkPeerings" {
  for_each = local.networking.vnet_peerings

  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01"
  name      = "${var.global_settings.name}-${each.value.name}"
  parent_id = can(each.value.from.id) ? each.value.from.id : azurerm_virtual_network.vnet[each.value.from.vnet_key].id

  body = jsonencode({
    properties = {
      allowForwardedTraffic     = try(each.value.allow_forwarded_traffic, false)
      allowGatewayTransit       = try(each.value.allow_gateway_transit, false)
      allowVirtualNetworkAccess = try(each.value.allow_virtual_network_access, true)
      doNotVerifyRemoteGateways = try(each.value.do_not_verify_remote_gateways, false)
      useRemoteGateways         = try(each.value.use_remote_gateways, false)
      remoteVirtualNetwork = {
        id = can(each.value.to.remote_virtual_network_id) ? each.value.to.remote_virtual_network_id : azurerm_virtual_network.vnet[each.value.to.vnet_key].id
      }
    }
  })
}


module "diagnostic_log_analytics" {
  source   = "../../services/logmon/log_analytics"
  for_each = local.diagnostics.diagnostic_log_analytics

  global_settings     = var.global_settings
  log_analytics       = each.value
  location            = var.global_settings.location
  resource_group_name = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : azurerm_resource_group.rg[try(each.value.resource_group_key, each.value.resource_group.key)].name
  tags                = try(var.tags, {})
}


module "diagnostic_log_analytics_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = local.diagnostics.diagnostic_log_analytics

  resource_id       = module.diagnostic_log_analytics[each.key].id
  resource_location = module.diagnostic_log_analytics[each.key].location
  diagnostics       = local.combined_diagnostics
  profiles          = try(each.value.diagnostic_profiles, {})
}


module "subscription_diagnostics" {
  source            = "../../services/logmon/diagnostics"
  resource_id       = var.global_settings.client_config.subscription_id
  resource_location = var.global_settings.location
  diagnostics       = local.combined_diagnostics
  profiles = {
    subscription_diag = {
      definition_key   = "subscription_operations"
      destination_type = "log_analytics"
      destination_key  = "central_logs"
    }
  }
}
