
resource "azurerm_key_vault" "kv" {
  name                            = "${var.global_settings.name}-${var.settings.name}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tenant_id                       = var.global_settings.client_config.tenant_id
  sku_name                        = lookup(var.settings, "sku_name", "standard")
  enabled_for_deployment          = lookup(var.settings, "enabled_for_deployment", false)
  enabled_for_disk_encryption     = lookup(var.settings, "enabled_for_disk_encryption", false)
  enabled_for_template_deployment = lookup(var.settings, "enabled_for_template_deployment", false)
  purge_protection_enabled        = lookup(var.settings, "purge_protection_enabled", false)
  soft_delete_retention_days      = lookup(var.settings, "soft_delete_retention_days", 7)
  enable_rbac_authorization       = lookup(var.settings, "enable_rbac_authorization", false)
  tags                            = var.tags

  dynamic "network_acls" {
    for_each = lookup(var.settings, "network", null) == null ? [] : [1]

    content {
      default_action = lookup(var.settings.network, "default_action", "Deny")
      bypass         = var.settings.network.bypass
      ip_rules       = lookup(var.settings.network, "ip_rules", null)
      virtual_network_subnet_ids = lookup(var.settings.network, "subnets", null) == null ? null : [
        for key, value in var.settings.network.subnets : can(value.subnet_id) ? value.subnet_id : var.settings.virtual_subnets[value.subnet_key].id
      ]
    }
  }

  dynamic "contact" {
    for_each = lookup(var.settings, "contacts", {})

    content {
      email = contact.value.email
      name  = lookup(contact.value, "name", null)
      phone = lookup(contact.value, "phone", null)
    }
  }

  lifecycle {
    ignore_changes = [
      resource_group_name, location
    ]
  }

  timeouts {
    delete = "60m"
  }
}


module "diagnostics" {
  source = "../../../logmon/diagnostics"

  resource_id       = azurerm_key_vault.kv.id
  resource_location = azurerm_key_vault.kv.location
  diagnostics       = lookup(var.combined_objects_core, "diagnostics", {})
  profiles          = lookup(var.settings, "diagnostic_profiles", {})
}

