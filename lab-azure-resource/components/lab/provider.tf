terraform {
  required_version = ">= 1.5.0"
  backend "azurerm" {} // When using remote
  #backend "local" {} // When using local
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  subscription_id            = var.subscription_id
  skip_provider_registration = "true"
  features {}
  alias = "labs"
}

provider "azurerm" {
  subscription_id            = var.hub_sbox_subscription_id
  skip_provider_registration = "true"
  features {}
  alias = "hub-sbox"
}

provider "azurerm" {
  subscription_id            = "ed302caf-ec27-4c64-a05e-85731c3ce90e" # Update current VPN subscription id if this no longer exists
  skip_provider_registration = "true"
  features {}
  alias = "vpn"
}