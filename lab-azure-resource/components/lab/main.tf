
locals {
  prefix      = formatdate("YYYYMMDDhhmmss", timestamp())
  rg_name     = "labs-rg-${local.prefix}"
  vnet_name   = "labs-vnet-${local.prefix}"
  pip_name    = "labs-ip-${local.prefix}"
  nsg_name    = "labs-nsg-${local.prefix}"
  nic_name    = "labs-nic-${local.prefix}"
  rt_name     = "labs-rt-${local.prefix}"
  vm_name     = "labs-vm-${local.prefix}"
  common_tags = module.ctags.common_tags
}

resource "azurerm_resource_group" "res-0" {
  location = var.location
  name     = local.rg_name
}

resource "azurerm_virtual_network" "res-8" {
  name                = local.vnet_name
  location            = azurerm_resource_group.res-0.location
  resource_group_name = azurerm_resource_group.res-0.name
  address_space       = [var.address_space]
  tags                = local.common_tags
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}

resource "azurerm_subnet" "res-9" {
  name = "subnet"
  // Dont do this in a live environment.
  // Assignment, try split the address space into two /26 subnets and use the first one
  address_prefixes     = [var.address_space]
  resource_group_name  = azurerm_resource_group.res-0.name
  virtual_network_name = azurerm_virtual_network.res-8.name
  depends_on = [
    azurerm_virtual_network.res-8
  ]
}

resource "azurerm_route_table" "res-6" {
  name                = local.rt_name
  location            = azurerm_resource_group.res-0.location
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = local.common_tags
  depends_on = [
    azurerm_resource_group.res-0
  ]
}

resource "azurerm_subnet_route_table_association" "res-11" {
  route_table_id = azurerm_route_table.res-6.id
  subnet_id      = azurerm_subnet.res-9.id
  depends_on = [
    azurerm_route_table.res-6,
    azurerm_subnet.res-9,
    azurerm_subnet_network_security_group_association.res-10
  ]
}

resource "azurerm_public_ip" "res-5" {
  name                = local.pip_name
  location            = azurerm_resource_group.res-0.location
  resource_group_name = azurerm_resource_group.res-0.name
  allocation_method   = "Static"
  domain_name_label   = local.pip_name
  sku                 = "Standard"
  tags                = local.common_tags
  depends_on = [
    azurerm_resource_group.res-0
  ]
}

resource "azurerm_network_security_group" "res-4" {
  name                = local.nsg_name
  location            = azurerm_resource_group.res-0.location
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = local.common_tags
  depends_on = [
    azurerm_resource_group.res-0
  ]
}

resource "azurerm_network_interface" "res-3" {
  name                = local.nic_name
  location            = azurerm_resource_group.res-0.location
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = local.common_tags
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.res-9.id
  }
  depends_on = [
    azurerm_subnet.res-9
  ]
}

resource "azurerm_subnet_network_security_group_association" "res-10" {
  network_security_group_id = azurerm_network_security_group.res-4.id
  subnet_id                 = azurerm_subnet.res-9.id
  depends_on = [
    azurerm_network_security_group.res-4
  ]
}

resource "azurerm_route" "res-7" {
  address_prefix         = "0.0.0.0/0"
  name                   = "Default"
  next_hop_in_ip_address = "10.10.200.36" // Hub lb private frontend ip (Trust zone)
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = azurerm_resource_group.res-0.name
  route_table_name       = azurerm_route_table.res-6.name
  depends_on = [
    azurerm_route_table.res-6
  ]
}

resource "azurerm_linux_virtual_machine" "res-2" {
  admin_username                  = "labsAdmin2023"
  admin_password                  = "Wednesday!"
  location                        = azurerm_resource_group.res-0.location
  name                            = local.vnet_name
  network_interface_ids           = [azurerm_network_interface.res-3.id]
  resource_group_name             = azurerm_resource_group.res-0.name
  size                            = "Standard_D2ds_v5"
  disable_password_authentication = false
  tags                            = local.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  plan {
    name      = "apache-ubuntu20-04"
    product   = "apache_ubuntu20-04"
    publisher = "cloud-infrastructure-services"
  }
  source_image_reference {
    offer     = "apache_ubuntu20-04"
    publisher = "cloud-infrastructure-services"
    sku       = "apache-ubuntu20-04"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.res-3
  ]
}

/*
 * Vnet peering module. Used when you want to pair vnets together
 * Peering for Palo Alto firewall
 */
module "vnet_peer_hub_sbox" {
  source = "github.com/hmcts/terraform-module-vnet-peering"

  peerings = {
    source = {
      name           = format("%s%s_To_%s", "labs-${local.prefix}", var.environment, "hmcts-hub-sbox-int")
      vnet           = azurerm_virtual_network.res-8.name
      resource_group = azurerm_virtual_network.res-8.resource_group_name
    }
    target = {
      name           = format("%s_To_%s%s", "hmcts-hub-sbox-int", "labs-${local.prefix}", var.environment)
      vnet           = "hmcts-hub-sbox-int"
      resource_group = "hmcts-hub-sbox-int"
    }
  }

  providers = {
    azurerm.initiator = azurerm.labs
    azurerm.target    = azurerm.hub-sbox
  }

  depends_on = [
    azurerm_virtual_network.res-8
  ]
}

/*
 * Vnet peering module. Used when you want to pair vnets together
 * Peering for VPN access
 */
module "vnet_peer_vpn" {
  source = "github.com/hmcts/terraform-module-vnet-peering"

  peerings = {
    source = {
      name           = format("%s%s_To_%s", "labs-${local.prefix}", var.environment, "core-infra-vnet-mgmt")
      vnet           = azurerm_virtual_network.res-8.name
      resource_group = azurerm_virtual_network.res-8.resource_group_name
    }
    target = {
      name           = format("%s_To_%s%s", "core-infra-vnet-mgmt", "labs-${local.prefix}", var.environment)
      vnet           = "core-infra-vnet-mgmt"
      resource_group = "rg-mgmt"
    }
  }

  providers = {
    azurerm.initiator = azurerm.labs
    azurerm.target    = azurerm.vpn
  }
}

/*
* Tagging module. To be used for every resource that supports tags
*/
module "ctags" {
  source      = "git::https://github.com/hmcts/terraform-module-common-tags.git?ref=master"
  environment = var.environment
  product     = var.product
  builtFrom   = var.builtFrom
}