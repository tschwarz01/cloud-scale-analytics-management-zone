resource "random_string" "prefix" {
  count   = try(var.global_settings.prefix, null) == null ? 1 : 0
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
      client_id               = data.azurerm_client_config.default.client_id
      tenant_id               = data.azurerm_client_config.default.tenant_id
      subscription_id         = data.azurerm_subscription.current.id
      object_id               = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
      logged_user_objectId    = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
      logged_aad_app_objectId = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
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
    connectivity_hub_virtual_network_id = var.connectivity_hub_virtual_network_id

    // Management Zone virtual network
    vnet_address_cidr            = var.vnet_address_cidr
    services_subnet_cidr         = var.services_subnet_cidr
    private_endpoint_subnet_cidr = var.private_endpoint_subnet_cidr
    data_gateway_subnet_cidr     = var.data_gateway_subnet_cidr

    // DNS
    private_dns_zones_subscription_id     = try(var.private_dns_zones_subscription_id, null)
    private_dns_zones_resource_group_name = try(var.private_dns_zones_resource_group_name, null)
    remote_private_dns_zones              = try(var.remote_private_dns_zones, null)
    local_private_dns_zones               = try(var.local_private_dns_zones, null)

    // Azure Firewall
    deploy_azure_firewall = var.deploy_azure_firewall
    firewall_subnet_cidr  = try(var.deploy_azure_firewall, false) == true ? var.firewall_subnet_cidr : null
    gateway_subnet_cidr   = try(var.deploy_azure_firewall, false) == true ? var.gateway_subnet_cidr : null

  }


  integration_module_settings = {
    deploy_shir                                           = var.deploy_dmlz_shared_integration_runtime
    data_factory_self_hosted_runtime_authorization_script = try(var.data_factory_self_hosted_runtime_authorization_script, null)
    vmss_instance_count                                   = try(var.vmss_instance_count, 2)
    vmss_vm_sku                                           = try(var.vmss_vm_sku, null)
    vmss_admin_username                                   = try(var.vmss_admin_username, "adminuser")
  }

  automation_module_settings = {
    enable_free_tier = var.cosmosdb_use_free_tier
  }

  consumption_module_settings = {}
  governance_module_settings  = {}


  #########################################
  ##      Derived Settings / Variables
  #########################################

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
