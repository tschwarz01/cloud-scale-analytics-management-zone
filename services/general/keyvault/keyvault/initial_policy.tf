module "initial_policy" {
  source          = "../keyvault_access_policies"
  count           = try(var.settings.creation_policies, null) == null ? 0 : 1
  keyvault_id     = azurerm_key_vault.kv.id
  access_policies = var.settings.creation_policies
  client_config   = var.global_settings.client_config
}
