variable "global_settings" {
  default = {}
}
variable "location" {
  description = "The location of the resource group"
  type        = string
}
variable "environment" {
  description = "The release stage of the environment"
  default     = "dev"
  type        = string
}
variable "tags" {
  description = "Tags that should be applied to all deployed resources"
  type        = map(string)
}
variable "prefix" {
  default = null
  type    = string
}

// FEATURE FLAGS

variable "deploy_azure_firewall" {
  type        = bool
  description = "(true || false) Should Azure Firewall be deployed within the Data Management Landing Zone?"
  default     = false
}


// NETWORKING

variable "connectivity_hub_virtual_network_id" {
  description = "Virtual network resource id of the regional hub connectivity virtual network."
  type        = string
}
variable "vnet_address_cidr" {
  description = "Address space to use for the Management Zone virtual network"
  type        = string
}
variable "services_subnet_cidr" {
  type        = string
  description = "Address space to use for the Shared Services subnet within the Management Zone virtual network."
}
variable "private_endpoint_subnet_cidr" {
  type        = string
  description = "Address space to use for the Private Endpoint subnet within the Management Zone virtual network."
}
variable "data_gateway_subnet_cidr" {
  type        = string
  description = "Address space to use for the Power BI / Power Platform vnet data gateway subnet within the Management Zone virtual network."
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "Address space to use for the Azure Firewall subnet within the Management Zone virtual network."
}

variable "gateway_subnet_cidr" {
  type        = string
  description = "Address space to use for the Virtual Network Gateway subnet within the Management Zone VNet"
}
variable "private_dns_zones_subscription_id" {
  type        = string
  description = "The id of the subscription where remote Private DNS Zones are deployed."
  default     = null
}
variable "private_dns_zones_resource_group_name" {
  type        = string
  description = "Name of the resource group in the remote subscriptions where remote Private DNS Zones are deployed."
  default     = null
}
variable "remote_private_dns_zones" {
  type = map(object({
    create_vnet_links_to_remote_zones = bool
    vnet_key                          = string
    subscription_id                   = string
    resource_group_name               = string
    private_dns_zones                 = list(string)
  }))
  description = "List of Private DNS Zone names from the remote subscription that will be linked to the Data Management Zone"
  default     = {}
}
variable "local_private_dns_zones" {
  description = "List of Private DNS Zone names to be created in the Data Management Zone subscription"
  default     = {}
  type = map(object({
    create_local_private_dns_zones = bool
    vnet_key                       = string
    resource_group_name            = optional(string)
    resource_group_key             = optional(string)
    private_dns_zones              = list(string)
  }))
}

variable "deploy_dmlz_shared_integration_runtime" {
  type        = bool
  description = "Feature flag which determines if shared Data Factory Integration Runtime compute resources will be managed in the Data Management Zone subscription."
  default     = true
}

variable "data_factory_self_hosted_runtime_authorization_script" {
  type        = string
  description = "The URI of the script which will be executed to register Virtual Machines with an Azure Data Factory Self-Hosted Integration Runtime."
  default     = null
}
variable "vmss_vm_sku" {
  type        = string
  description = "The VM SKU that will be used for the VMSS instances used by the Data Factory Self-Hosted Integration Runtime."
  default     = "Standard_D4d_v4"
}
variable "vmss_instance_count" {
  type        = number
  description = "The number of instances to be used in the VMSS (1 - 4)."
}
variable "vmss_admin_username" {
  type        = string
  description = "The Windows admin username that will be used by the VMSS instances."
  default     = "adminuser"
}
