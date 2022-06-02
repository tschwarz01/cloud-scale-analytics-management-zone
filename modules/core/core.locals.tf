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
      GatewaySubnet = {
        name     = "GatewaySubnet"
        cidr     = [var.module_settings.gateway_subnet_cidr]
        vnet_key = "vnet"
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

    remote_private_dns_zones = {
      for vnet, value in var.module_settings.remote_private_dns_zones : vnet => {
        vnet_key = try(value.vnet_key, null)
        private_dns_zones = {
          for zone in value.private_dns_zones : zone => {
            id                   = "/subscriptions/${value.subscription_id}/resourceGroups/${value.resource_group_name}/providers/Microsoft.Network/privateDnsZones/${zone}"
            name                 = zone
            registration_enabled = try(value.registration_enabled, false)
            is_remote            = true
          }
        }
      } if value.create_vnet_links_to_remote_zones == true
    }

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
  remote_pdns = {
    for k, v in local.ddi.remote_private_dns_zones["vnet"].private_dns_zones : v.name => v.id
  }


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

  diagnostics_definition = {
    log_analytics = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["Audit", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    default_all = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AuditEvent", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    bastion_host = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["BastionAuditLogs", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    networking_all = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["VMProtectionAlerts", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    public_ip_address = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["DDoSProtectionNotifications", true, false, 7],
          ["DDoSMitigationFlowLogs", true, false, 7],
          ["DDoSMitigationReports", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    load_balancer = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          ["LoadBalancerAlertEvent", true, false, 7],
          ["LoadBalancerProbeHealthStatus", true, false, 7],
        ]
        metric = [
          ["AllMetrics", true, false, 7]
        ]
      }
    }
    network_security_group = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["NetworkSecurityGroupEvent", true, false, 7],
          ["NetworkSecurityGroupRuleCounter", true, false, 7],
        ]
      }
    }
    network_interface_card = {
      name = "operational_logs_and_metrics"
      categories = {
        # log = [
        #   # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
        #   ["AuditEvent", true, false, 7],
        # ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    private_dns_zone = {
      name = "operational_logs_and_metrics"
      categories = {
        # log = [
        #   # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
        #   ["AuditEvent", true, false, 7],
        # ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    azure_container_registry = {
      name                           = "operational_logs_and_metrics"
      log_analytics_destination_type = "Dedicated"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["ContainerRegistryRepositoryEvents", true, false, 7],
          ["ContainerRegistryLoginEvents", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    azure_key_vault = {
      name                           = "operational_logs_and_metrics"
      log_analytics_destination_type = "Dedicated"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AuditEvent", true, false, 7],
          ["AzurePolicyEvaluationDetails", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    azure_data_factory = {
      name                           = "operational_logs_and_metrics"
      log_analytics_destination_type = "Dedicated"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["ActivityRuns", true, false, 7],
          ["PipelineRuns", true, false, 7],
          ["TriggerRuns", true, false, 7],
          ["SandboxPipelineRuns", true, false, 7],
          ["SandboxActivityRuns", true, false, 7],
          ["SSISPackageEventMessages", true, false, 7],
          ["SSISPackageExecutableStatistics", true, false, 7],
          ["SSISPackageEventMessageContext", true, false, 7],
          ["SSISPackageExecutionComponentPhases", true, false, 7],
          ["SSISPackageExecutionDataStatistics", true, false, 7],
          ["SSISIntegrationRuntimeLogs", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    purview_account = {
      name                           = "operational_logs_and_metrics"
      log_analytics_destination_type = "Dedicated"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["ScanStatusLogEvent", true, false, 7],
          ["DataSensitivityLogEvent", true, false, 7],
          ["Security", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    azure_kubernetes_cluster = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["kube-apiserver", true, false, 7],
          ["kube-audit", true, false, 7],
          ["kube-audit-admin", true, false, 7],
          ["kube-controller-manager", true, false, 7],
          ["kube-scheduler", true, false, 7],
          ["cluster-autoscaler", true, false, 7],
          ["guard", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    azure_site_recovery = {
      name                           = "operational_logs_and_metrics"
      log_analytics_destination_type = "Dedicated"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AzureBackupReport", true, true, 7],
          ["CoreAzureBackup", true, true, 7],
          ["AddonAzureBackupAlerts", true, true, 7],
          ["AddonAzureBackupJobs", true, true, 7],
          ["AddonAzureBackupPolicy", true, true, 7],
          ["AddonAzureBackupProtectedInstance", true, true, 7],
          ["AddonAzureBackupStorage", true, true, 7],
          ["AzureSiteRecoveryJobs", true, true, 7],
          ["AzureSiteRecoveryEvents", true, true, 7],
          ["AzureSiteRecoveryReplicatedItems", true, true, 7],
          ["AzureSiteRecoveryReplicationStats", true, true, 7],
          ["AzureSiteRecoveryRecoveryPoints", true, true, 7],
          ["AzureSiteRecoveryReplicationDataUploadRate", true, true, 7],
          ["AzureSiteRecoveryProtectedDiskDataChurn", true, true, 30],
        ]
        metric = [
          #["AllMetrics", 60, True],
        ]
      }
    }
    azure_automation = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["JobLogs", true, true, 30],
          ["JobStreams", true, true, 30],
          ["DscNodeStatus", true, true, 30],
        ]
        metric = [
          # ["Category name",  "Metric Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, true, 30],
        ]
      }
    }
    event_hub_namespace = {
      name = "operational_logs_and_metrics"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["ArchiveLogs", true, false, 7],
          ["OperationalLogs", true, false, 7],
          ["AutoScaleLogs", true, false, 7],
          ["KafkaCoordinatorLogs", true, false, 7],
          ["KafkaUserErrorLogs", true, false, 7],
          ["EventHubVNetConnectionEvent", true, false, 7],
          ["CustomerManagedKeyUserLogs", true, false, 7],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", true, false, 7],
        ]
      }
    }
    compliance_all = {
      name = "compliance_logs"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AuditEvent", true, true, 365],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", false, false, 7],
        ]
      }
    }
    siem_all = {
      name = "siem"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AuditEvent", true, true, 0],
        ]
        metric = [
          #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["AllMetrics", false, false, 0],
        ]
      }
    }
    subscription_operations = {
      name = "subscription_operations"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)"]
          ["Administrative", true],
          ["Security", true],
          ["ServiceHealth", true],
          ["Alert", true],
          ["Policy", true],
          ["Autoscale", true],
          ["ResourceHealth", true],
          ["Recommendation", true],
        ]
      }
    }
    subscription_siem = {
      name = "activity_logs_for_siem"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)"]
          ["Administrative", false],
          ["Security", true],
          ["ServiceHealth", false],
          ["Alert", false],
          ["Policy", true],
          ["Autoscale", false],
          ["ResourceHealth", false],
          ["Recommendation", false],
        ]
      }
    }
    azure_sql_database = {
      name                           = "operational_logs_and_metrics"
      log_analytics_destination_type = "Dedicated"
      categories = {
        log = [
          # ["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
          ["SQLInsights", true, true, 7],
          ["AutomaticTuning", true, true, 7],
          ["QueryStoreRuntimeStatistics", true, true, 7],
          ["QueryStoreWaitStatistics", true, true, 7],
          ["Errors", true, true, 7],
          ["DatabaseWaitStatistics", true, true, 7],
          ["Timeouts", true, true, 7],
          ["Blocks", true, true, 7],
          ["Deadlocks", true, true, 7],
          ["DevOpsOperationsAudit", true, true, 7],
          ["SQLSecurityAuditEvents", true, true, 7],
          ["AzureSiteRecoveryRecoveryPoints", true, true, 7],
          ["AzureSiteRecoveryReplicationDataUploadRate", true, true, 7],
          ["AzureSiteRecoveryProtectedDiskDataChurn", true, true, 30],
        ]
        metric = [
          ["InstanceAndAppAdvanced", true, false, 7],
          ["WorkloadManagement", true, false, 7],
        ]
      }
    }
  }
}
