locals {
  location            = "westus2"
  resource_group_name = "viper-vpn-rg"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}