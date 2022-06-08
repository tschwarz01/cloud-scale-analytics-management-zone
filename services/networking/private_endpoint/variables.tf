
variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  default     = null
}
variable "resource_group_name" {
  description = "The name of the resource group. Changing this forces a new resource to be created."
  default     = null
}
variable "resource_id" {
  type    = string
  default = null
}
variable "name" {
  type        = string
  description = "(Required) Specifies the name. Changing this forces a new resource to be created."
}
variable "private_service_connection" {
  description = "A private_service_connection block"
}
variable "private_dns_zones" {
  description = "Private DNS Zones object containing details about all zones deployed by this template."
}
variable "subnet_id" {
  default = null
}
variable "private_dns" {
  default = {}
}
variable "tags" {
  default = {}
}



variable "settings" {}




