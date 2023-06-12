terraform {
  backend "local" {} // Remove if using GitHub and Azure DevOps
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.57.0"
    }
  }
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
  subscription_id            = "ed302caf-ec27-4c64-a05e-85731c3ce90e"
  skip_provider_registration = "true"
  features {}
  alias = "vpn"
}