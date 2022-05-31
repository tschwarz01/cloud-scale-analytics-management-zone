variable "global_settings" {
  description = "Global settings object (see module README.md)"
}
variable "log_analytics" {}
variable "resource_group_name" {}
variable "location" {}
variable "tags" {
  type        = map(any)
}