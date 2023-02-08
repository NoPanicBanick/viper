#### Variables ####
variable "vm_username" {
  type = string
}

variable "vm_password" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v3"
  validation {
    condition     = contains(["Standard_D4s_v3", "Standard_D8s_v3"], var.vm_size)
    error_message = "Invalid vm size.  Valid options include \"Standard_D4s_v3\" and \"Standard_D8s_v3\""
  }
}

#### Local Config ####
locals {
  location            = "Australia Central"
  resource_group_name = "viper-vm-rg"
  static_rg_name      = "viper-vm-static-rg"

  public_ip_name = "viper-vm-publicip"
  subnet_name    = "vm1"

  virtual_network_interface_name = "viper-vnet-nic"
  virtual_network_name           = "viper-vm"
  vnet_name                      = "viper-vnet"

  vm_name                      = "viper-vm"
  vm_os_drive_name             = "viper-os-disk"
  vm_shared_image_name         = "viper-vm-image"
  vm_shared_image_gallery_name = "banickvmgallery"
}

#### Data Sources ####
data "azurerm_resource_group" "static_rg" {
  name = local.static_rg_name
}

data "azurerm_public_ip" "ip" {
  name                = local.public_ip_name
  resource_group_name = data.azurerm_resource_group.static_rg.name
}

data "azurerm_managed_disk" "os_disk" {
  name = local.vm_os_drive_name
  resource_group_name = data.azurerm_resource_group.static_rg.name
}

#### Resources ####
resource "azurerm_resource_group" "rg" {
  name = local.resource_group_name
  location = local.location
}

resource "azurerm_virtual_network" "network" {
  name                = local.virtual_network_name
  address_space       = ["10.0.0.0/28"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.0.0/29"]
}

resource "azurerm_network_interface" "example" {
  name                = local.virtual_network_interface_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = data.azurerm_public_ip.ip.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                             = local.vm_name
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  network_interface_ids            = [azurerm_network_interface.example.id]
  delete_data_disks_on_termination = false
  delete_os_disk_on_termination    = false
  vm_size                          = var.vm_size

  os_profile_windows_config {
    enable_automatic_upgrades = false
    timezone                  = "New Zealand Standard Time"
    provision_vm_agent        = false
  }

  storage_os_disk {
    name            = local.vm_os_drive_name
    caching         = "ReadWrite"
    create_option   = "Attach"
    os_type         = "Windows"
    managed_disk_id = data.azurerm_managed_disk.os_disk.id
  }
}

resource "azurerm_virtual_machine_extension" "nvidia" {
  name                 = "NvidiaGpuDriverWindows"
  virtual_machine_id   = azurerm_virtual_machine.main.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "Microsoft.HpcCompute.NvidiaGpuDriverWindows"
  type_handler_version = "1.*"
}
  
  # You can apply this the first time to setup an os disk.  Then comment out
#   os_profile {
#     computer_name  = local.vm_name
#     admin_username = var.vm_username
#     admin_password = var.vm_password
#   }

#   storage_image_reference {
#     publisher = "MicrosoftWindowsDesktop" # setup windows 10 base
#     offer     = "Windows-10"              # setup windows 10 base
#     sku       = "20h1-pro"                # setup windows 10 base
#     version   = "latest"                  # setup windows 10 base
#   }

#   storage_os_disk {
#     name              = local.vm_os_drive_name
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "StandardSSD_LRS"
#     disk_size_gb      = 128
#   }
}
