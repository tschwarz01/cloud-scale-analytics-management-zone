#########################################
## General Settings

location    = "southcentralus"
environment = "dev"
tags = {
  Org = "Cloud Ops"
}

#########################################
## Core Network Settings

vnet_address_cidr                   = "10.11.0.0/21"
services_subnet_cidr                = "10.11.0.0/24"
private_endpoint_subnet_cidr        = "10.11.1.0/24"
gateway_subnet_cidr                 = "10.11.2.0/26"
data_gateway_subnet_cidr            = "10.11.2.128/25"
connectivity_hub_virtual_network_id = "/subscriptions/893395a4-65a3-4525-99ea-2378c6e0dbed/resourceGroups/rg-network_connectivity_hub/providers/Microsoft.Network/virtualNetworks/vnet-connectivity_hub"

###########################################
## Private DNS Zone Settings - 
## Remote Subscription Hosted Zones

remote_private_dns_zones = {
  vnet = {

    create_vnet_links_to_remote_zones = true
    vnet_key                          = "vnet"
    subscription_id                   = "c00669a2-37e9-4e0d-8b57-4e8dd0fcdd4a"
    resource_group_name               = "rg-scus-pe-lab-network"

    private_dns_zones = [
      "privatelink.blob.core.windows.net",
      "privatelink.dfs.core.windows.net",
      "privatelink.queue.core.windows.net",
      "privatelink.vaultcore.azure.net",
      "privatelink.datafactory.azure.net",
      "privatelink.adf.azure.com",
      "privatelink.purview.azure.com",
      "privatelink.purviewstudio.azure.com",
      "privatelink.servicebus.windows.net",
      "privatelink.azurecr.io",
      "privatelink.azuresynapse.net",
      "privatelink.sql.azuresynapse.net",
      "privatelink.dev.azuresynapse.net"
    ]

  }
}

#######################################
## Private DNS Zones Settings - 
## Zones to Create in the Data Management Zone

local_private_dns_zones = {

  vnet = {

    create_local_private_dns_zones = true
    vnet_key                       = "vnet"
    resource_group_key             = "network"
    private_dns_zones              = ["privatelink.cognitiveservices.azure.com", "privatelink.mongo.cosmos.azure.com"]

  }
}

########################################
# Integration Module Settings

data_factory_self_hosted_runtime_authorization_script = "https://raw.githubusercontent.com/Azure/data-landing-zone/main/code/installSHIRGateway.ps1"
vmss_vm_sku                                           = "Standard_D4d_v4"
vmss_instance_count                                   = 2
vmss_admin_username                                   = "adminuser"

