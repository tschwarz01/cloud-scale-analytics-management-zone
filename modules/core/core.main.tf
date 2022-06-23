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
  tags     = var.tags
}


resource "azurerm_network_security_group" "nsg" {
  for_each = local.networking.network_security_groups

  name                = "${var.global_settings.name}-${each.value.name}"
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  location            = each.value.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = lookup(each.value, "nsg", [])

    content {
      name                         = lookup(security_rule, "name", null)
      priority                     = lookup(security_rule, "priority", null)
      direction                    = lookup(security_rule, "direction", null)
      access                       = lookup(security_rule, "access", null)
      protocol                     = lookup(security_rule, "protocol", null)
      source_port_range            = lookup(security_rule, "source_port_range", null)
      source_port_ranges           = lookup(security_rule, "source_port_ranges", null)
      destination_port_range       = lookup(security_rule, "destination_port_range", null)
      destination_port_ranges      = lookup(security_rule, "destination_port_ranges", null)
      source_address_prefix        = lookup(security_rule, "source_address_prefix", null)
      source_address_prefixes      = lookup(security_rule, "source_address_prefixes", null)
      destination_address_prefix   = lookup(security_rule, "destination_address_prefix", null)
      destination_address_prefixes = lookup(security_rule, "destination_address_prefixes", null)
    }
  }
}


resource "azurerm_virtual_network" "vnet" {
  for_each = local.networking.vnets

  name                = "${var.global_settings.name}-${each.value.vnet.name}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  address_space       = each.value.vnet.address_space
  dns_servers         = var.module_settings.deploy_azure_firewall == true ? [cidrhost(var.module_settings.firewall_subnet_cidr, 4)] : null
  tags                = var.tags
}


resource "azurerm_subnet" "snet" {
  for_each = local.networking.subnets

  name                 = "${var.global_settings.name}-${each.value.name}"
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) == null ? [] : [each.value.delegation]

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
  for_each = { for key, val in local.networking.specialsubnets : key => val if var.module_settings.deploy_azure_firewall == true }

  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr
}


locals {
  subnets = merge(azurerm_subnet.snet, azurerm_subnet.ssnet, {})
}


module "azure_firewall" {
  for_each = lookup(var.module_settings, "deploy_azure_firewall", false) == true ? lookup(local.networking, "firewalls", {}) : {}
  source   = "../../services/networking/azfirewall"

  global_settings      = var.global_settings
  resource_group_name  = azurerm_resource_group.rg[each.value.resource_group_key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  sku_name             = each.value.sku_name
  sku_tier             = each.value.sku_tier
  firewall_subnet_id   = local.subnets["fw_subnet"].id
  name                 = each.value.name
  dns_ip_address       = cidrhost(var.module_settings.firewall_subnet_cidr, 4)
  # gateway_subnet_id    = local.subnets["gw_subnet"].id

}


resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = { for key, value in local.networking.subnets : key => value if can(value.nsg_key) == true }

  subnet_id                 = local.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_key].id
}


module "private_dns" {
  for_each = local.ddi.local_private_dns_zones
  source   = "../../services/networking/private_dns"

  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  global_settings     = var.global_settings
  virtual_network_id  = azurerm_virtual_network.vnet[coalesce(each.key, each.value.vnet_key)].id
  private_dns_zones   = each.value.private_dns_zones
  tags                = var.tags
}


resource "azapi_resource" "remote_vnet_links" {
  for_each  = lookup(var.module_settings, "remote_private_dns_zones", {})
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01"
  location  = "global"
  name      = "${var.global_settings.name}-${each.key}"
  parent_id = each.value

  body = jsonencode({
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azurerm_virtual_network.vnet["vnet"].id
      }
    }
  })
  tags = var.tags
}


resource "azapi_resource" "virtualNetworkPeerings" {
  for_each = { for key, value in local.networking.vnet_peerings : key => value if var.module_settings.create_connectivity_hub_peerings == true }

  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01"
  name      = "${var.global_settings.name}-${each.value.name}"
  parent_id = can(each.value.from.id) ? each.value.from.id : azurerm_virtual_network.vnet[each.value.from.vnet_key].id

  body = jsonencode({
    properties = {
      allowForwardedTraffic     = lookup(each.value, "allow_forwarded_traffic", false)
      allowGatewayTransit       = lookup(each.value, "allow_gateway_transit", false)
      allowVirtualNetworkAccess = lookup(each.value, "allow_virtual_network_access", true)
      doNotVerifyRemoteGateways = lookup(each.value, "do_not_verify_remote_gateways", false)
      useRemoteGateways         = lookup(each.value, "use_remote_gateways", false)
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
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  tags                = var.tags
}


module "diagnostic_log_analytics_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = local.diagnostics.diagnostic_log_analytics

  resource_id       = module.diagnostic_log_analytics[each.key].id
  resource_location = module.diagnostic_log_analytics[each.key].location
  diagnostics       = local.combined_diagnostics
  profiles          = lookup(each.value, "diagnostic_profiles", {})
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
