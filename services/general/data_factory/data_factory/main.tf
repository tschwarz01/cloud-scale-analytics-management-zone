
resource "azurerm_data_factory" "df" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "github_configuration" {
    for_each = try(var.settings.github_configuration, null) != null ? [var.settings.github_configuration] : []

    content {
      account_name    = github_configuration.value.account_name
      branch_name     = github_configuration.value.branch_name
      git_url         = github_configuration.value.git_url
      repository_name = github_configuration.value.repository_name
      root_folder     = github_configuration.value.root_folder
    }
  }

  dynamic "global_parameter" {
    for_each = try(var.settings.global_parameter, null) != null ? [var.settings.global_parameter] : []

    content {
      name  = global_parameter.value.name
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }

  dynamic "identity" {
    for_each = lookup(var.settings, "enable_system_msi", false) == false ? [] : [1]

    content {
      type = "SystemAssigned"
    }
  }

  dynamic "vsts_configuration" {
    for_each = try(var.settings.vsts_configuration, null) != null ? [var.settings.vsts_configuration] : []

    content {
      account_name    = vsts_configuration.value.account_name
      branch_name     = vsts_configuration.value.branch_name
      project_name    = vsts_configuration.value.project_name
      repository_name = vsts_configuration.value.repository_name
      root_folder     = vsts_configuration.value.root_folder
      tenant_id       = vsts_configuration.value.tenant_id
    }
  }

  managed_virtual_network_enabled = true
  public_network_enabled          = false
  #customer_managed_key_id         = try(var.settings.customer_managed_key_id)
  tags = var.tags
}


module "self_hosted_integration_runtimes" {
  source   = "./integration_runtime_self_hosted"
  for_each = lookup(var.settings, "self_hosted_integration_runtimes", {})

  data_factory_id = azurerm_data_factory.df.id
  name            = "${var.global_settings.name}-${each.value.name}"
  description     = try(each.value.description, null)
  settings        = each.value
}


module "diagnostics" {
  source = "../../../logmon/diagnostics"

  resource_id       = azurerm_data_factory.df.id
  resource_location = azurerm_data_factory.df.location
  diagnostics       = try(var.combined_objects_core.diagnostics, {})
  profiles          = try(var.settings.diagnostic_profiles, {})
}
