

variable "name" {
  type        = string
  description = "(Required) Specifies the name. Changing this forces a new resource to be created."
}

variable "resource_group_name" {
  description = "The name of the resource group. Changing this forces a new resource to be created."
  default     = null
}

variable "subnet_id" {
  default = null
}

variable "location" {
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  default     = null
}

variable "resource_id" {
  type    = string
  default = null
}

variable "settings" {}

variable "private_dns" {
  default = {}
}

variable "tags" {
  default = {}
}
