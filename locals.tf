
resource "random_string" "prefix" {

  count   = lookup(var.global_settings, "prefix", null) == null ? 1 : 0
  length  = 4
  special = false
  upper   = false
  numeric = false
}


locals {

  global_settings = {
    location    = var.location
    prefix      = random_string.prefix[0].result
    environment = var.environment
    name        = lower("${random_string.prefix[0].result}-${var.environment}")
    name_clean  = lower("${random_string.prefix[0].result}${var.environment}")
    tags        = merge(local.base_tags, var.tags, {})

    client_config = {
      client_id       = data.azurerm_client_config.default.client_id
      tenant_id       = data.azurerm_client_config.default.tenant_id
      subscription_id = data.azurerm_subscription.current.id
      #object_id               = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
      object_id               = data.azurerm_client_config.default.object_id
      logged_user_objectId    = data.azurerm_client_config.default.object_id
      logged_aad_app_objectId = data.azurerm_client_config.default.object_id
    }
  }


  base_tags = {
    Solution = "CAF Cloud Scale Analytics"
    Project  = "Data Management Landing Zone"
    Toolkit  = "Terraform"
  }


  #########################################
  ##          Module Settings
  #########################################

  core_module_settings = {

    // Connectivity Hub peering
    create_connectivity_hub_peerings    = var.create_connectivity_hub_peerings
    connectivity_hub_virtual_network_id = var.create_connectivity_hub_peerings == true ? var.connectivity_hub_virtual_network_id : null

    // Management Zone virtual network
    vnet_address_cidr            = var.vnet_address_cidr
    services_subnet_cidr         = var.services_subnet_cidr
    private_endpoint_subnet_cidr = var.private_endpoint_subnet_cidr
    data_gateway_subnet_cidr     = var.data_gateway_subnet_cidr

    // DNS
    remote_private_dns_zones = local.remote_private_dns_zones
    local_private_dns_zones  = var.local_private_dns_zones

    // Azure Firewall
    deploy_azure_firewall = var.deploy_azure_firewall
    firewall_subnet_cidr  = var.deploy_azure_firewall == true ? var.firewall_subnet_cidr : null
    gateway_subnet_cidr   = var.deploy_azure_firewall == true ? var.gateway_subnet_cidr : null

  }


  integration_module_settings = {
    deploy_shir                                           = var.deploy_dmlz_shared_integration_runtime
    data_factory_self_hosted_runtime_authorization_script = var.data_factory_self_hosted_runtime_authorization_script
    vmss_instance_count                                   = var.vmss_instance_count
    vmss_vm_sku                                           = var.vmss_vm_sku
    vmss_admin_username                                   = var.vmss_admin_username
  }


  automation_module_settings = {
    enable_free_tier = var.cosmosdb_use_free_tier
  }


  consumption_module_settings = {}


  governance_module_settings = {}


  #########################################
  ##      Derived Settings / Variables
  #########################################

  remote_private_dns_zones = {
    for zone in var.dns_zones_remote_zones : zone =>
    "/subscriptions/${var.dns_zones_remote_subscription_id}/resourceGroups/${var.dns_zones_remote_resource_group}/providers/Microsoft.Network/privateDnsZones/${zone}"
  }

  combined_objects_core = {
    resource_groups   = merge(module.core.resource_groups, {})
    virtual_networks  = merge(module.core.virtual_networks, {})
    virtual_subnets   = merge(module.core.virtual_subnets, {})
    private_dns_zones = merge(module.core.local_pdns, module.core.remote_pdns, {})
    diagnostics       = module.core.diagnostics
  }


  combined_objects_consumption = {
    shared_image_galleries   = merge(module.consumption.shared_image_galleries, {})
    container_registries     = merge(module.consumption.container_registries, {})
    synapse_privatelink_hubs = merge(module.consumption.synapse_privatelink_hubs, {})
    private_endpoints        = merge(module.consumption.private_endpoints, {})
  }


  combined_objects_governance = {
    purview_accounts  = merge(module.governance.purview_accounts, {})
    private_endpoints = merge(module.governance.private_endpoints, {})
  }
}
