
resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  data_factory_id = var.data_factory_id
  name            = var.name
  description     = var.description

  dynamic "rbac_authorization" {
    for_each = lookup(var.settings, "host_data_factory", null) == null ? [] : [var.settings.host_data_factory]

    content {
      resource_id = lookup(rbac_authorization.value, "host_runtime_resource_id", null)
    }
  }
}
