
#########################################
##          General Settings
#########################################
location    = "southcentralus"
environment = "dev"
tags = {
  Org = "Cloud Ops"
}


#########################################
##    Management Zone Feature Flags
#########################################

# Peer Management Zone to CAF Platform Connectivity Hub  (Regional Hub Network)
create_connectivity_hub_peerings = true

# Only necessary if there is not an existing connectivity hub network in your environment
deploy_azure_firewall = true

# True if Data Factory Integration Runtime compute resources should be centrally managed within the Data Management Zone and shared with spoke Data Landing Zones.
deploy_dmlz_shared_integration_runtime = true


#########################################
##        Core Network Settings
#########################################
connectivity_hub_virtual_network_id = "/subscriptions/893395a4-65a3-4525-99ea-2378c6e0dbed/resourceGroups/rg-network_connectivity_hub/providers/Microsoft.Network/virtualNetworks/vnet-connectivity_hub"
vnet_address_cidr                   = "10.11.0.0/21"

## Required Subnets
services_subnet_cidr         = "10.11.0.0/24"
private_endpoint_subnet_cidr = "10.11.1.0/24"
data_gateway_subnet_cidr     = "10.11.2.128/25"

## if deploy_zure_firewall = true
firewall_subnet_cidr = "10.11.2.64/26"
gateway_subnet_cidr  = "10.11.2.0/26"


#########################################
##      Private DNS Zone Settings - 
##    Remote Subscription Hosted Zones
#########################################

dns_zones_remote_subscription_id = "c00669a2-37e9-4e0d-8b57-4e8dd0fcdd4a"
dns_zones_remote_resource_group  = "rg-scus-pe-lab-network"
dns_zones_remote_zones = [
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
  "privatelink.dev.azuresynapse.net",
  "privatelink.database.windows.net",
  "privatelink.search.windows.net",
  "privatelink.cognitiveservices.azure.com",
  "privatelink.api.azureml.ms",
  "privatelink.file.core.windows.net",
  "privatelink.notebooks.azure.net",
  "privatelink.documents.azure.com"
]

#######################################
##     Private DNS Zones Settings - 
## Zones to Create in the Data Management Zone
#########################################
local_private_dns_zones = {

  vnet = {

    create_local_private_dns_zones = true
    vnet_key                       = "vnet"
    resource_group_key             = "network"

    private_dns_zones = [
      "privatelink.mongo.cosmos.azure.com"
    ]

  }
}


#########################################
#     Integration Module Settings
#########################################
data_factory_self_hosted_runtime_authorization_script = "https://raw.githubusercontent.com/Azure/data-landing-zone/main/code/installSHIRGateway.ps1"
vmss_vm_sku                                           = "Standard_D4d_v4"
vmss_instance_count                                   = 2
vmss_admin_username                                   = "adminuser"


#########################################
##         Automation Settings
#########################################
cosmosdb_use_free_tier = false #true
