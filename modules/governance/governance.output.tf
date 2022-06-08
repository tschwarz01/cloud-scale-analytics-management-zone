
output "private_endpoints" {
  value = module.private_endpoints
}


output "purview_accounts" {
  value = {
    id                          = azurerm_purview_account.pva["pva1"].id
    identity                    = azurerm_purview_account.pva["pva1"].identity
    name                        = azurerm_purview_account.pva["pva1"].name
    resource_group_name         = azurerm_purview_account.pva["pva1"].resource_group_name
    public_network_enabled      = azurerm_purview_account.pva["pva1"].public_network_enabled
    managed_resource_group_name = azurerm_purview_account.pva["pva1"].managed_resource_group_name
    managed_resources           = azurerm_purview_account.pva["pva1"].managed_resources
    catalog_endpoint            = azurerm_purview_account.pva["pva1"].catalog_endpoint
    guardian_endpoint           = azurerm_purview_account.pva["pva1"].guardian_endpoint
    scan_endpoint               = azurerm_purview_account.pva["pva1"].scan_endpoint
  }
}


output "keyvaults" {
  value = module.keyvault
}


