resource "azurerm_storage_account" "storageaccount" {
  name                     = var.storageAccount
  resource_group_name      = var.resourceGroup
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["70.123.100.80", "104.9.97.45"]
    virtual_network_subnet_ids = [azurerm_subnet.vnetsubnetNet.id]
  }

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "blobstorage" {
  name                  = var.storageContainer
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = "private"
}
