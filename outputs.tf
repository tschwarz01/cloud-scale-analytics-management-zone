
locals {
  dlz_params = {

    connectivity_hub_vnet_id             = var.connectivity_hub_virtual_network_id
    mgmt_zone_vnet_id                    = module.core.virtual_networks["vnet"].id
    mgmt_zone_vnet_cidr                  = module.core.virtual_networks["vnet"].address_space
    mgmt_zone_factory_id                 = var.deploy_dmlz_shared_integration_runtime == true ? module.integration.data_factory["df1"].id : null
    mgmt_zone_shir_id                    = var.deploy_dmlz_shared_integration_runtime == true ? module.integration.data_factory["df1"].self_hosted_integration_runtime["dfirsh1"].id : null
    log_analytics_workspace_resource_id  = module.core.diagnostics.log_analytics["central_logs_region1"].id
    log_analytics_workspace_workspace_id = module.core.diagnostics.log_analytics["central_logs_region1"].workspace_id
  }
}

output "dlz_params" {
  value = local.dlz_params
}
