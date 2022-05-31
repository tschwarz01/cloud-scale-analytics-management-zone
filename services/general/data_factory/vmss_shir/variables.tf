variable "global_settings" {
  description = "Global settings object (see module README.md)"
}
variable "location" {
  description = "Specifies the supported Azure location where to create the resource. Changing this forces a new resource to be created."
  default     = null
}
variable "resource_group_name" {
  description = "Name of the existing resource group to deploy the virtual machine"
  default     = null
}
variable "combined_objects_core" {
  default = {}
}
variable "settings" {}
variable "tags" {
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource"
}
variable "shir_authorization_key" {
  description = "The Data Factory Self-Hosted Integration Runtime authorization key."
  type        = string
}
variable "custom_script_fileuri" {
  type        = string
  description = "Resource URI containing the script used by VMSS Custom Script Extension to join associate the VMSS with a Self-Hosted Integration Runtime."
}
variable "keyvaults" {
  default = {}
}
variable "keyvault_id" {
  type    = string
  default = "null"

}
