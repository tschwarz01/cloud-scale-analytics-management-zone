output "data_factory" {
  value = module.data_factory
}

output "keyvault" {
  value = module.keyvault
}

output "shir_authorization_key" {
  value = module.data_factory["df1"].self_hosted_integration_runtime["dfirsh1"].primary_authorization_key
}

