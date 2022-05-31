resource "random_password" "admin" {
  for_each         = (local.os_type == "windows") && (try(var.settings.vmss_settings["windows"].admin_password_key, null) == null) ? var.settings.vmss_settings : {}
  length           = 123
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  number           = true
  special          = true
  override_special = "!@#$%&"
}
resource "azurerm_key_vault_secret" "admin_password" {
  for_each     = local.os_type == "windows" && try(var.settings.vmss_settings[local.os_type].admin_password_key, null) == null ? var.settings.vmss_settings : {}
  name         = format("%s-admin-password", "${var.global_settings.name}-${each.value.name}-shir")
  value        = random_password.admin[local.os_type].result
  key_vault_id = local.keyvault.id
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
locals {
  os_type  = "windows"
  keyvault = try(var.keyvaults[var.settings.keyvault_key], var.keyvault_id)
  #admin_username = try(data.external.windows_admin_username.0.result.value, null)
  #admin_password = try(data.external.windows_admin_password.0.result.value, null)
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  depends_on = [
    azurerm_lb_rule.lb_rule
  ]
  for_each = local.os_type == "windows" ? var.settings.vmss_settings : {}

  admin_password      = try(each.value.admin_password_key, null) == null ? random_password.admin[local.os_type].result : null
  admin_username      = try(each.value.admin_username_key, null) == null ? each.value.admin_username : null
  instances           = try(each.value.instances, 2)
  location            = try(var.location, var.global_settings.location)
  name                = "shir00"
  resource_group_name = var.resource_group_name
  sku                 = each.value.sku
  tags                = var.tags

  computer_name_prefix         = "shir00"
  custom_data                  = try(each.value.custom_data, null) == null ? null : filebase64(format("%s/%s", path.cwd, each.value.custom_data))
  priority                     = "Spot"
  eviction_policy              = "Deallocate"
  max_bid_price                = try(each.value.max_bid_price, null)
  provision_vm_agent           = try(each.value.provision_vm_agent, true)
  proximity_placement_group_id = null
  scale_in_policy              = try(each.value.scale_in_policy, null)
  zone_balance                 = try(each.value.zone_balance, null)
  zones                        = try(each.value.zones, null)
  timezone                     = try(each.value.timezone, null)
  license_type                 = try(each.value.license_type, null)
  upgrade_mode                 = "Automatic"
  health_probe_id              = azurerm_lb_probe.lb_probe.id

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT30M" # Use ISO8601 expressions.
  }
  automatic_os_upgrade_policy {
    disable_automatic_rollback  = false
    enable_automatic_os_upgrade = false
  }
  network_interface {
    name                          = "${var.global_settings.name}-${each.value.name}-nic"
    primary                       = true
    enable_accelerated_networking = try(each.value.network_interface.enable_accelerated_networking, false)
    enable_ip_forwarding          = try(each.value.network_interface.value.enable_ip_forwarding, false)
    network_security_group_id     = try(each.value.network_interface.value.network_security_group_id, null)
    ip_configuration {
      name                                   = "${var.global_settings.name}-${each.value.name}-ipconfig"
      primary                                = true
      subnet_id                              = var.combined_objects_core.virtual_subnets[var.settings.subnet_key].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_address_pool.id]
      application_security_group_ids         = null
      #load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lb-nat-pool.id]
    }
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }
  rolling_upgrade_policy {
    max_batch_instance_percent              = 60
    max_unhealthy_instance_percent          = 60
    max_unhealthy_upgraded_instance_percent = 60
    pause_time_between_batches              = "PT01M"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  extension {
    name                 = "custom_script"
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    settings             = <<SETTINGS
        {
            "fileUris": [
                "https://raw.githubusercontent.com/Azure/data-landing-zone/main/code/installSHIRGateway.ps1"
                ]
        }
    SETTINGS
    protected_settings   = <<PROTECTED_SETTINGS
      {
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File installSHIRGateway.ps1 -gatewayKey ${var.shir_authorization_key}"
      }
      PROTECTED_SETTINGS
  }
}
