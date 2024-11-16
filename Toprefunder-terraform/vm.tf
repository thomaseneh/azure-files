resource "azurerm_public_ip" "publicIP" {
  name                = "toprefunderPublicIP"
  resource_group_name = var.resourceGroup
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "networkInterface" {
  name                = "toprefundNetworkInterface"
  location            = var.location
  resource_group_name = var.resourceGroup

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnetsubnetNet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicIP.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "toprefunderVM"
  resource_group_name = var.resourceGroup
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.networkInterface.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/teneh/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}