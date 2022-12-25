locals {
  location            = "Australia East"
  resource_group_name = "viper-vm-rg"

  dns_zone_name    = "imnotaddicted.com"
  dns_zone_rg_name = "banick-dns-rg"
  public_ip_name   = "viper-vm-publicip"
}

#### Data Sources ####   
data "azurerm_resource_group" "rg" {
  name = local.resource_group_name
}

data "azurerm_dns_zone" "dnszone" {
  name                = local.dns_zone_name
  resource_group_name = local.dns_zone_rg_name
}

#### Resources ####
resource "azurerm_public_ip" "ip" {
  name                = local.public_ip_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "azurerm_dns_a_record" "base_address_a_record" {
  name                = "@"
  zone_name           = data.azurerm_dns_zone.dnszone.name
  resource_group_name = data.azurerm_dns_zone.dnszone.resource_group_name
  ttl                 = 3600
  records             = ["${azurerm_public_ip.ip.ip_address}"]
}

resource "azurerm_dns_cname_record" "example" {
  name                = "www"
  zone_name           = data.azurerm_dns_zone.dnszone.name
  resource_group_name = data.azurerm_dns_zone.dnszone.resource_group_name
  ttl                 = 3600
  record              = azurerm_public_ip.ip.ip_address
}