variable "global_settings" {
  default = {}
}
variable "private_dns_zone_id" {
  type = string
}
variable "virtual_network_id" {
  type = string
}
variable "private_dns_zone_name" {
  type = string
}
variable "tags" {
  default = {}
}
variable "registration_enabled" {
  type    = bool
  default = false
}
