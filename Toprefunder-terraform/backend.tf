
# terraform {
#   backend "azurerm" {
#     storage_account_name = "storagedevops101"
#     container_name       = "tfstatefile101"
#     key                  = "terraform.tfstate"
#     # access_key = "${var.storage_account_key}" - export istead (export ARM_ACCESS_KEY="your-access-key-here"
#   }
# }

