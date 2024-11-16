terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.9.0"
    }
  }
}
provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "azKeyVault" {
  name                        = "keysSectrets"
  location                    = var.location
  resource_group_name         = var.resourceGroup
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

# data "azurerm_key_vault_secret" "storageKey" {
#   name         = "toprefunderWinpassword"
#   key_vault_id = azurerm_key_vault.azKeyVault.id
# }

# data "azurerm_key_vault_secret" "storageKey" {
#   name         = "storagedevops101Key"
#   key_vault_id = azurerm_key_vault.azKeyVault.id
# }
