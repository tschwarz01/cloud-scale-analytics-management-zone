output "purview_accounts" {
  value = azurerm_purview_account.pva
}

output "private_endpoints" {
  value = module.private_endpoints
}
