locals {
  location                       = "Australia East"
  gateway_name                   = "viper-vpn-gateway"
  resource_group_name            = "viper-vm-rg"
  subnet_name                    = "vm1"
  vnet_name                      = "viper-vnet"
  virtual_machine_name           = "viper-vm"
  virtual_network_interface_name = "viper-vnet-nic"
  virtual_network_name           = "viper-vm"

  public_ip_name   = "viper-vm-publicip"
}

#### Data Sources ####
data "azurerm_resource_group" "rg" {
  name = local.resource_group_name
}

data "azurerm_managed_disk" "disk" {
  name                = "viper-os-disk"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_public_ip" "ip" {
  name = local.public_ip_name
  resource_group_name = local.resource_group_name
}

#### Resources ####
resource "azurerm_virtual_network" "network" {
  name                = local.virtual_network_name
  address_space       = ["10.0.0.0/28"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.0.0/29"]
}

resource "azurerm_network_interface" "example" {
  name                = local.virtual_network_interface_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = data.azurerm_public_ip.ip.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                             = local.virtual_machine_name
  location                         = data.azurerm_resource_group.rg.location
  resource_group_name              = data.azurerm_resource_group.rg.name
  network_interface_ids            = [azurerm_network_interface.example.id]
  delete_data_disks_on_termination = false
  delete_os_disk_on_termination    = false
  vm_size                          = "Standard_D8s_v3"

  os_profile_windows_config {
    enable_automatic_upgrades = true
    timezone                  = "New Zealand Standard Time"
    provision_vm_agent        = false
  }

  # # You can apply this the first time to setup an os disk.  Then comment
  # os_profile {
  #   computer_name  = local.virtual_machine_name
  #   admin_username = "rbanick"
  #   admin_password = "Table-turtle99"
  # }

  # storage_image_reference {
  #   publisher = "MicrosoftWindowsDesktop"
  #   offer     = "Windows-10"
  #   sku       = "20h1-pro"
  #   version   = "latest"
  # }

  # storage_os_disk {
  #   name              = "viper-os-disk"
  #   caching           = "ReadWrite"
  #   create_option     = "FromImage"
  #   managed_disk_type = "StandardSSD_LRS"
  # }

  storage_os_disk {
    name            = "viper-os-disk"
    caching         = "ReadWrite"
    create_option   = "Attach"
    os_type         = "Windows"
    managed_disk_id = data.azurerm_managed_disk.disk.id
  }
}