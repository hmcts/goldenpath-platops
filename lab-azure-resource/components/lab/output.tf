output "lab_rg_name" {
  description = "The auto generated resource group name"
  value       = try(azurerm_resource_group.res-0[0].name, null)
}

output "lab_vnet_name" {
  description = "The auto generated resource vnet name"
  value       = try(azurerm_virtual_network.res-8[0].name, null)
}

output "lab_vnet_cidr" {
  description = "The vnet address space"
  value       = try(azurerm_virtual_network.res-8[0].address_space, null)
}
