output "id" {
  value = azurerm_data_factory.df.id
}

output "name" {
  value = azurerm_data_factory.df.name
}

output "identity" {
  value = azurerm_data_factory.df.identity
}

output "rbac_id" {
  value = azurerm_data_factory.df.identity[0].principal_id
}

output "self_hosted_integration_runtime" {
  value = module.self_hosted_integration_runtimes
}
