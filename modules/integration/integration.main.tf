
module "keyvault" {
  source   = "../../services/general/keyvault/keyvault"
  for_each = { for key, val in local.keyvaults : key => val if var.module_settings.deploy_shir == true }

  name                  = "${var.global_settings.name}-${each.value.name}"
  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : var.combined_objects_core.resource_groups[try(each.value.resource_group_key, each.value.resource_group.key)].name
  tags                  = var.tags
  combined_objects_core = var.combined_objects_core
}


resource "azurerm_role_assignment" "role_assignment" {
  depends_on = [module.keyvault]
  for_each   = { for key, val in local.role_assignments : key => val if var.module_settings.deploy_shir == true } #local.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}


module "data_factory" {
  source   = "../../services/general/data_factory/data_factory"
  for_each = { for key, val in local.data_factory : key => val if var.module_settings.deploy_shir == true } #local.data_factory

  name                  = "${var.global_settings.name}-${each.value.name}"
  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : var.combined_objects_core.resource_groups[try(each.value.resource_group_key, each.value.resource_group.key)].name
  tags                  = var.tags
  combined_objects_core = var.combined_objects_core
}


resource "time_sleep" "shirdelay" {
  depends_on = [azurerm_role_assignment.role_assignment]

  create_duration = "25s"
}


module "vmss_self_hosted_integration_runtime" {
  depends_on = [time_sleep.shirdelay]
  source     = "../../services/general/data_factory/vmss_shir"
  for_each   = { for key, val in local.vmss_self_hosted_integration_runtime : key => val if var.module_settings.deploy_shir == true } #try(local.vmss_self_hosted_integration_runtime, {})

  global_settings        = var.global_settings
  resource_group_name    = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location               = var.global_settings.location
  combined_objects_core  = var.combined_objects_core
  custom_script_fileuri  = each.value.data_factory_self_hosted_runtime_authorization_script
  shir_authorization_key = module.data_factory[each.value.data_factory_key].self_hosted_integration_runtime[each.value.integration_runtime_key].primary_authorization_key
  keyvaults              = module.keyvault
  keyvault_id            = module.keyvault["integration"].id
  settings               = each.value
  tags                   = var.tags
}
