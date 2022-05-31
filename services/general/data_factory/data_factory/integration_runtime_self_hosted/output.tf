output "id" {
  value = azurerm_data_factory_integration_runtime_self_hosted.shir.id
}
output "data_factory_id" {
  value = azurerm_data_factory_integration_runtime_self_hosted.shir.data_factory_id
}
output "description" {
  value = try(azurerm_data_factory_integration_runtime_self_hosted.shir.description, null)
}
output "name" {
  value = azurerm_data_factory_integration_runtime_self_hosted.shir.name
}
output "primary_authorization_key" {
  value = azurerm_data_factory_integration_runtime_self_hosted.shir.primary_authorization_key
}
output "secondary_authorization_key" {
  value = azurerm_data_factory_integration_runtime_self_hosted.shir.secondary_authorization_key
}
