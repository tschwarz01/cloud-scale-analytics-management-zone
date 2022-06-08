
resource "azurerm_public_ip" "pip" {
  name                    = "${var.global_settings.name}-fw-pip"
  location                = var.global_settings.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  sku                     = "Standard"
  ip_version              = "IPv4"
  idle_timeout_in_minutes = "4"
}


resource "azurerm_firewall_policy" "fw_policy" {
  name                     = "${var.global_settings.name}-firewall-policy"
  location                 = var.global_settings.location
  resource_group_name      = var.resource_group_name
  sku                      = "Premium"
  threat_intelligence_mode = "Deny"

  intrusion_detection {
    mode = "Deny"
  }

  dns {
    proxy_enabled = true
    # servers       = [var.dns_ip_address]
  }
}

output "firewall_policy" {
  value = azurerm_firewall_policy.fw_policy
}

resource "time_sleep" "after_azurerm_firewall_policies" {

  depends_on = [
    azurerm_firewall_policy.fw_policy
  ]

  create_duration = "10s"
}



resource "azurerm_firewall" "fw" {
  depends_on          = [time_sleep.after_azurerm_firewall_policies]
  name                = var.name
  location            = var.global_settings.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier

  ip_configuration {
    name                 = "public-ip"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
}


module "fw_policy_rules" {
  depends_on = [azurerm_firewall.fw]
  source     = "../azfirewall_policy_rules"

  fw_policy_id = azurerm_firewall_policy.fw_policy.id
}
