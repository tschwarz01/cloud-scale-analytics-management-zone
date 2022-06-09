locals {

  resource_groups = {
    network = {
      name     = "network"
      location = var.global_settings.location
    }
    management = {
      name     = "management"
      location = var.global_settings.location
    }
    logmon = {
      name     = "logging-and-monitoring"
      location = var.global_settings.location
    }
    integration = {
      name     = "integration"
      location = var.global_settings.location
    }
    governance = {
      name     = "governance"
      location = var.global_settings.location
    }
    consumption = {
      name     = "consumption"
      location = var.global_settings.location
    }
    # container = {
    #   name     = "container"
    #   location = var.global_settings.location
    # }
    marketplace = {
      name     = "marketplace"
      location = var.global_settings.location
    }
    meshservices = {
      name     = "mesh-services"
      location = var.global_settings.location
    }
    sharedservices = {
      name     = "shared-services"
      location = var.global_settings.location
    }
    automation = {
      name     = "automation"
      location = var.global_settings.location
    }
  }


  networking = {
    vnets = {
      vnet = {
        location           = var.global_settings.location
        resource_group_key = "network"
        vnet = {
          name          = "caf-csa-mz-vnet"
          address_space = [var.module_settings.vnet_address_cidr]
        }
      }
    }

    subnets = {
      services = {
        name     = "services"
        cidr     = [var.module_settings.services_subnet_cidr]
        vnet_key = "vnet"
        nsg_key  = "empty_nsg"
      }
      private_endpoints = {
        name                                           = "private-endpoints"
        cidr                                           = [var.module_settings.private_endpoint_subnet_cidr]
        enforce_private_link_endpoint_network_policies = true
        vnet_key                                       = "vnet"
        nsg_key                                        = "empty_nsg"
      }
      data_gateway = {
        name     = "data-gateway"
        cidr     = [var.module_settings.data_gateway_subnet_cidr]
        vnet_key = "vnet"
        nsg_key  = "empty_nsg"
        delegation = {
          name               = "power-platform-delegation"
          service_delegation = "Microsoft.PowerPlatform/vnetaccesslinks"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      }
    }


    specialsubnets = {

      gw_subnet = {
        name     = "GatewaySubnet"
        cidr     = [var.module_settings.gateway_subnet_cidr]
        vnet_key = "vnet"
      }

      fw_subnet = {
        name     = "AzureFirewallSubnet" # must be named AzureFirewallSubnet
        cidr     = [var.module_settings.firewall_subnet_cidr]
        vnet_key = "vnet"
      }
    }


    firewalls = {
      fw01 = {
        name                 = "dmlz-firewall"
        resource_group_key   = "network"
        vnet_key             = "vnet"
        subnet_key           = "AzureFirewallSubnet"
        sku_name             = "AZFW_VNet"
        sku_tier             = "Premium"
        gateway_subnet_cidr  = var.module_settings.gateway_subnet_cidr
        firewall_subnet_cidr = var.module_settings.firewall_subnet_cidr
      }
    }


    network_security_groups = {
      empty_nsg = {
        version            = 1
        resource_group_key = "network"
        location           = var.global_settings.location
        name               = "empty_nsg"
        nsg                = []
      }
    }


    vnet_peerings = {
      dmlz_to_hub = {
        name = "dmz_to_connectivity_hub"
        from = {
          vnet_key = "vnet"
        }
        to = {
          remote_virtual_network_id = var.module_settings.connectivity_hub_virtual_network_id
        }
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = true
      }

      hub_to_dmlz = {
        name = "region1_connectivity_hub_to_dmz"
        from = {
          id = var.module_settings.connectivity_hub_virtual_network_id
        }
        to = {
          vnet_key = "vnet"
        }
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = true
        use_remote_gateways          = false
      }
    }
  }


  ddi = {

    local_private_dns_zones = {
      for vnet, value in var.module_settings.local_private_dns_zones : vnet => {
        vnet_key           = try(value.vnet_key, null)
        resource_group_key = value.resource_group_key
        private_dns_zones = {
          for zone in value.private_dns_zones : zone => {
            #id   = "/subscriptions/${value.subscription_id}/resourceGroups/${value.resource_group_name}/providers/Microsoft.Network/privateDnsZones/${zone}"
            registration_enabled = try(value.registration_enabled, false)
            name                 = zone
            is_remote            = false
          }
        }
      } if value.create_local_private_dns_zones == true
    }
  }


  local_pdns = {
    for k, v in module.private_dns["vnet"].private_dns_zones : v.name => v.id
  }

  remote_pdns = var.module_settings.remote_private_dns_zones


  diagnostics = {
    diagnostic_log_analytics = try(local.diagnostic_log_analytics, {})
  }


  combined_diagnostics = {
    diagnostics_definition   = try(local.diagnostics_definition, {})
    diagnostics_destinations = try(local.diagnostics_destinations, {})
    log_analytics            = try(module.diagnostic_log_analytics, {})
  }


  diagnostic_log_analytics = {
    central_logs_region1 = {
      name               = "logs"
      resource_group_key = "logmon"
      solutions_maps = {
        NetworkMonitoring = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/NetworkMonitoring"
        },
        ADAssessment = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/ADAssessment"
        },
        ADReplication = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/ADReplication"
        },
        AgentHealthAssessment = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/AgentHealthAssessment"
        },
        DnsAnalytics = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/DnsAnalytics"
        },
        ContainerInsights = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/ContainerInsights"
        },
        KeyVaultAnalytics = {
          "publisher" = "Microsoft"
          "product"   = "OMSGallery/KeyVaultAnalytics"
        }
      }
    }
  }


  diagnostics_destinations = {
    # Storage keys must reference the azure region name
    log_analytics = {
      central_logs = {
        log_analytics_key = "central_logs_region1"
      }
    }
  }

}
