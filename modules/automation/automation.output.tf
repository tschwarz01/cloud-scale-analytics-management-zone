
output "cosmosdb_accounts" {
  value = azurerm_cosmosdb_account.acct
}


output "cosmosdb_sql_databases" {
  value = azurerm_cosmosdb_sql_database.db
}


output "private_endpoints" {
  value = module.private_endpoints
}
