
resource "azurerm_container_registry" "acr" {
  name                = "containerRegistry10101"
  resource_group_name = var.resourceGroup
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false
#   georeplications {
#     location                = "West US"
#     zone_redundancy_enabled = true
#     tags                    = {}
#   }
#   georeplications {
#     location                = "North Europe"
#     zone_redundancy_enabled = true
#     tags                    = {}
#   }
}