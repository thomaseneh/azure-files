
# provision resource group
resource "azurerm_resource_group" "resourceG" {
  name     = var.resourceGroup
  location = var.location
  tags = {
    name = "toprefunderResourceG"
  }
}