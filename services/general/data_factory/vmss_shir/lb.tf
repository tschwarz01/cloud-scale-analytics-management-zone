resource "azurerm_public_ip" "pip" {
  name                    = "${var.global_settings.name}-${var.settings.vmss_settings.windows.name}-pip"
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku                     = "Basic"
  allocation_method       = "Dynamic"
  ip_version              = "IPv4"
  idle_timeout_in_minutes = 4
  tags                    = var.tags
}
resource "azurerm_lb" "lb" {
  name                = "${var.global_settings.name}-${var.settings.vmss_settings.windows.name}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  sku                 = "Basic"
  frontend_ip_configuration {
    name                 = "feipconfig"
    public_ip_address_id = azurerm_public_ip.pip.id
    #subnet_id = var.combined_objects_core.virtual_subnets[var.settings.subnet_key].id
  }
}
resource "azurerm_lb_backend_address_pool" "backend_address_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.settings.vmss_settings.windows.name}-backend-pool"
}
resource "azurerm_lb_probe" "lb_probe" {
  depends_on = [
    azurerm_lb_backend_address_pool.backend_address_pool, azurerm_lb.lb
  ]
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.global_settings.name}-${var.settings.vmss_settings.windows.name}-probe"
  port            = 3389
}
resource "azurerm_lb_rule" "lb_rule" {
  depends_on = [
    azurerm_lb_backend_address_pool.backend_address_pool, azurerm_lb_probe.lb_probe
  ]
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "rule1"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_address_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}
