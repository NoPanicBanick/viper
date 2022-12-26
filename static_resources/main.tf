locals {
  location       = "Australia Central"
  static_rg_name = "viper-vm-static-rg"

  disk_name      = "viper-os-disk"
  dns_zone_name  = "imnotaddicted.com"
  public_ip_name = "viper-vm-publicip"
}

#### Resources ####
resource "azurerm_resource_group" "static_rg" {
  name     = local.static_rg_name
  location = local.location
}

resource "azurerm_dns_zone" "public_dns" {
  name                = local.dns_zone_name
  resource_group_name = local.static_rg_name
}

resource "azurerm_public_ip" "ip" {
  name                = local.public_ip_name
  resource_group_name = azurerm_resource_group.static_rg.name
  location            = azurerm_resource_group.static_rg.location
  allocation_method   = "Static"
}

resource "azurerm_dns_a_record" "base_address_a_record" {
  name                = "@"
  zone_name           = azurerm_dns_zone.public_dns.name
  resource_group_name = azurerm_dns_zone.public_dns.resource_group_name
  ttl                 = 3600
  records             = ["${azurerm_public_ip.ip.ip_address}"]
}

resource "azurerm_dns_cname_record" "example" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_dns.name
  resource_group_name = azurerm_dns_zone.public_dns.resource_group_name
  ttl                 = 3600
  record              = azurerm_public_ip.ip.ip_address
}