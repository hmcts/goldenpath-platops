locals {
  prefix      = formatdate("YYMMDDhhmm", timestamp())
  rg_name     = "labs-rg-${local.prefix}"
  vnet_name   = "labs-vnet-${local.prefix}"
  pip_name    = "labs-ip-${local.prefix}"
  nsg_name    = "labs-nsg-${local.prefix}"
  nic_name    = "labs-nic-${local.prefix}"
  rt_name     = "labs-rt-${local.prefix}"
  vm_name     = "labs-vm-${local.prefix}"
  kv_name     = format("labs-kv-%s", local.prefix)
  common_tags = module.ctags.common_tags
}

resource "azurerm_resource_group" "res-0" {
  count     = var.deploy ? 1 : 0
  location  = var.location
  name      = local.rg_name
}

resource "azurerm_virtual_network" "res-8" {
  count               = var.deploy ? 1 : 0
  name                = local.vnet_name
  location            = azurerm_resource_group.res-0[0].location
  resource_group_name = azurerm_resource_group.res-0[0].name
  address_space       = [var.address_space]
  tags                = local.common_tags
}

resource "azurerm_subnet" "res-9" {
  count                = var.deploy ? 1 : 0
  name                 = "subnet"
  // Dont do this in a live environment.
  // Assignment, try split the address space into two /26 subnets and use the first one
  address_prefixes     = [var.address_space]
  resource_group_name  = azurerm_resource_group.res-0[0].name
  virtual_network_name = azurerm_virtual_network.res-8[0].name
}

resource "azurerm_route_table" "res-6" {
  count               = var.deploy ? 1 : 0
  name                = local.rt_name
  location            = azurerm_resource_group.res-0[0].location
  resource_group_name = azurerm_resource_group.res-0[0].name
  tags                = local.common_tags
}

resource "azurerm_subnet_route_table_association" "res-11" {
  count          = var.deploy ? 1 : 0
  route_table_id = azurerm_route_table.res-6[0].id
  subnet_id      = azurerm_subnet.res-9[0].id
  depends_on = [
    azurerm_subnet_network_security_group_association.res-10
  ]
}

resource "azurerm_network_security_group" "res-4" {
  count               = var.deploy ? 1 : 0
  name                = local.nsg_name
  location            = azurerm_resource_group.res-0[0].location
  resource_group_name = azurerm_resource_group.res-0[0].name
  tags                = local.common_tags
}

resource "azurerm_network_interface" "res-3" {
  count               = var.deploy ? 1 : 0
  name                = local.nic_name
  location            = azurerm_resource_group.res-0[0].location
  resource_group_name = azurerm_resource_group.res-0[0].name
  tags                = local.common_tags
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.res-9[0].id
  }
}

resource "azurerm_subnet_network_security_group_association" "res-10" {
  count                     = var.deploy ? 1 : 0
  network_security_group_id = azurerm_network_security_group.res-4[0].id
  subnet_id                 = azurerm_subnet.res-9[0].id
}

resource "azurerm_route" "res-7" {
  count                  = var.deploy ? 1 : 0
  address_prefix         = "0.0.0.0/0"
  name                   = "Default"
  next_hop_in_ip_address = "10.10.200.36" // Hub lb private frontend ip (Trust zone)
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = azurerm_resource_group.res-0[0].name
  route_table_name       = azurerm_route_table.res-6[0].name
}

resource "random_password" "res-20" {
  count            = var.deploy ? 1 : 0
  length           = 20
  special          = true
  override_special = "!%*?"
}

resource "azurerm_key_vault" "res-12" {
  count                      = var.deploy ? 1 : 0
  location                   = azurerm_resource_group.res-0[0].location
  name                       = substr(local.kv_name, 0, 20)
  resource_group_name        = azurerm_resource_group.res-0[0].name
  sku_name                   = "standard"
  tenant_id                  = var.tenant_id
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  tags                       = local.common_tags
}

resource "azurerm_key_vault_secret" "vm-password" {
  count        = var.deploy ? 1 : 0
  key_vault_id = azurerm_key_vault.res-12[0].id
  name         = "vm-password"
  value        = random_password.res-20[0].result
}

data "azuread_group" "kv_access" {
  display_name     = "DTS Platform Operations"
  security_enabled = true
}

resource "azurerm_role_assignment" "kv-access" {
  count                = var.deploy ? 1 : 0
  principal_id         = data.azuread_group.kv_access.object_id
  scope                = azurerm_key_vault.res-12[0].id
  role_definition_name = "Key Vault Secrets User"
}


resource "azurerm_linux_virtual_machine" "res-2" {
  count                           = var.deploy ? 1 : 0
  admin_username                  = "labsAdmin2023"
  admin_password                  = random_password.res-20[0].result
  location                        = azurerm_resource_group.res-0[0].location
  name                            = local.vnet_name
  network_interface_ids           = [azurerm_network_interface.res-3[0].id]
  resource_group_name             = azurerm_resource_group.res-0[0].name
  size                            = "Standard_D2ds_v5"
  disable_password_authentication = false
  tags                            = local.common_tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  plan {
    name      = "apache-ubuntu-24-04"
    product   = "apache_ubuntu20-04"
    publisher = "cloud-infrastructure-services"
  }
  source_image_reference {
    offer     = "apache_ubuntu20-04"
    publisher = "cloud-infrastructure-services"
    sku       = "apache-ubuntu-24-04"
    version   = "1.0.6"
  }
}

/*
 * Vnet peering module. Used when you want to pair vnets together
 * Peering for Palo Alto firewall
 */
module "vnet_peer_hub_sbox" {
  count  = var.deploy ? 1 : 0
  source = "github.com/hmcts/terraform-module-vnet-peering"

  peerings = {
    source = {
      name           = format("%s%s_To_%s", "labs-${local.prefix}", var.environment, "hmcts-hub-sbox-int")
      vnet           = azurerm_virtual_network.res-8[0].name
      resource_group = azurerm_virtual_network.res-8[0].resource_group_name
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
}

/*
 * Vnet peering module. Used when you want to pair vnets together
 * Peering for VPN access
 */
module "vnet_peer_vpn" {
  count  = var.deploy ? 1 : 0
  source = "github.com/hmcts/terraform-module-vnet-peering"

  peerings = {
    source = {
      name           = format("%s%s_To_%s", "labs-${local.prefix}", var.environment, "core-infra-vnet-mgmt")
      vnet           = azurerm_virtual_network.res-8[0].name
      resource_group = azurerm_virtual_network.res-8[0].resource_group_name
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
