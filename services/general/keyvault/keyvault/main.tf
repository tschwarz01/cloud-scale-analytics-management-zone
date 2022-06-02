
resource "azurerm_key_vault" "kv" {
  name                            = "${var.global_settings.name}-${var.settings.name}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tenant_id                       = var.global_settings.client_config.tenant_id
  sku_name                        = try(var.settings.sku_name, "standard")
  enabled_for_deployment          = try(var.settings.enabled_for_deployment, false)
  enabled_for_disk_encryption     = try(var.settings.enabled_for_disk_encryption, false)
  enabled_for_template_deployment = try(var.settings.enabled_for_template_deployment, false)
  purge_protection_enabled        = try(var.settings.purge_protection_enabled, false)
  soft_delete_retention_days      = try(var.settings.soft_delete_retention_days, 7)
  enable_rbac_authorization       = try(var.settings.enable_rbac_authorization, false)
  tags                            = try(var.tags, {})

  dynamic "network_acls" {
    for_each = lookup(var.settings, "network", null) == null ? [] : [1]

    content {
      default_action = try(var.settings.network.default_action, "Deny")
      bypass         = var.settings.network.bypass
      ip_rules       = try(var.settings.network.ip_rules, null)
      virtual_network_subnet_ids = try(var.settings.network.subnets, null) == null ? null : [
        for key, value in var.settings.network.subnets : can(value.subnet_id) ? value.subnet_id : var.settings.virtual_subnets[value.subnet_key].id
      ]
    }
  }

  dynamic "contact" {
    for_each = lookup(var.settings, "contacts", {})

    content {
      email = contact.value.email
      name  = try(contact.value.name, null)
      phone = try(contact.value.phone, null)
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
  diagnostics       = try(var.combined_objects_core.diagnostics, {})
  profiles          = try(var.settings.diagnostic_profiles, {})
}

