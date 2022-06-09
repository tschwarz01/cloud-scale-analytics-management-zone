
locals {
  dlz_params = {
    create_connectivity_hub_peerings       = var.create_connectivity_hub_peerings
    deploy_dmlz_shared_integration_runtime = var.deploy_dmlz_shared_integration_runtime
    deploy_azure_firewall                  = var.deploy_azure_firewall

    azure_firewall_ip_address            = var.deploy_azure_firewall == true ? cidrhost(var.firewall_subnet_cidr, 4) : null
    connectivity_hub_vnet_id             = var.create_connectivity_hub_peerings == true ? var.connectivity_hub_virtual_network_id : null
    mgmt_zone_vnet_id                    = module.core.virtual_networks["vnet"].id
    mgmt_zone_vnet_cidr                  = module.core.virtual_networks["vnet"].address_space
    mgmt_zone_factory_id                 = var.deploy_dmlz_shared_integration_runtime == true ? module.integration.data_factory["df1"].id : null
    mgmt_zone_shir_id                    = var.deploy_dmlz_shared_integration_runtime == true ? module.integration.data_factory["df1"].self_hosted_integration_runtime["dfirsh1"].id : null
    log_analytics_workspace_resource_id  = module.core.diagnostics.log_analytics["central_logs_region1"].id
    log_analytics_workspace_workspace_id = module.core.diagnostics.log_analytics["central_logs_region1"].workspace_id
    private_dns_zones                    = merge(module.core.local_pdns, module.core.remote_pdns, {})
  }
}


output "dlz_params" {
  value = local.dlz_params
}
