
resource "azurerm_log_analytics_workspace" "law" {
  name                               = "${var.global_settings.name}-${var.log_analytics.name}"
  location                           = var.location
  resource_group_name                = var.resource_group_name
  daily_quota_gb                     = lookup(var.log_analytics, "daily_quota_gb", null)
  internet_ingestion_enabled         = lookup(var.log_analytics, "internet_ingestion_enabled", null)
  internet_query_enabled             = lookup(var.log_analytics, "internet_query_enabled", null)
  reservation_capacity_in_gb_per_day = lookup(var.log_analytics, "reservation_capcity_in_gb_per_day", null)
  sku                                = lookup(var.log_analytics, "sku", "PerGB2018")
  retention_in_days                  = lookup(var.log_analytics, "retention_in_days", 30)
  tags                               = var.tags
}
