resource "random_password" "res-20" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault" "res-21" {
  name                        = local.kv_name
  location                    = azurerm_resource_group.res-0.location
  resource_group_name         = azurerm_resource_group.res-0.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 1
  purge_protection_enabled    = false
  public_network_access_enabled = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
} 


resource "azurerm_key_vault_secret" "res-22" {
  name         = "${local.kv_name}-admin_password"
  value        = random_password.res-20.result
  key_vault_id = azurerm_key_vault.res-21.id
}
