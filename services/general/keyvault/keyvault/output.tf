output "id" {
  value = azurerm_key_vault.kv.id
}
output "vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
output "name" {
  value = azurerm_key_vault.kv.name
}
output "initial_policy" {
  value = module.initial_policy
}
