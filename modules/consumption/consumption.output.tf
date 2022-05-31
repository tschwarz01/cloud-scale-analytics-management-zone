output "shared_image_galleries" {
  value = azurerm_shared_image_gallery.sig
}

output "container_registries" {
  value = azurerm_container_registry.acr
}

output "synapse_privatelink_hubs" {
  value = azurerm_synapse_private_link_hub.plh
}

output "private_endpoints" {
  value = module.private_endpoints
}
