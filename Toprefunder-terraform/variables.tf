variable "resourceGroup" {
  type        = string
  description = "Resource Group for Toprefunder"
}

variable "location" {
  type        = string
  description = "Central US location"
}

variable "virtualNetwork" {
  type        = string
  description = "virtual network"
}

variable "storageAccount" {
  type        = string
  description = "Storage Acount 101"
}

variable "storageContainer" {
  type        = string
  description = "Storage Account Blob"
}

# variable "applicationGateway" {
#   type = string
#   description = "Application Gateway"
# }