variable "private_dns_zones" {
}

variable "resource_group_name" {
  type    = string
  default = null
}

variable "tags" {
  default = {}
}

variable "virtual_network_id" {
  type    = string
  default = null
}
