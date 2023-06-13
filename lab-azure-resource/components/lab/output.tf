output "lab_rg_name" {
  description = "The auto generated resource group name"
  value = azurerm_resource_group.res-0.name
}

output "lab_vnet_name" {
  description = "The auto generated resource vnet name"
  value = azurerm_virtual_network.res-8.name
}

output "lab_vnet_cidr" {
  description = "The vnet address space"
  value = azurerm_virtual_network.res-8.address_space
}
