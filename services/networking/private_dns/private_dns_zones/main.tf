resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

output "id" {
  value = azurerm_private_dns_zone.private_dns_zone.id
}

output "name" {
  value = azurerm_private_dns_zone.private_dns_zone.name
}

output "resource_group_name" {
  value = azurerm_private_dns_zone.private_dns_zone.resource_group_name
}
