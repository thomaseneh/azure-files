
# Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtualNetwork
  resource_group_name = var.resourceGroup
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  tags = {
    name = "toprefunderVnet"
  }
}
# Vnet Subnet
resource "azurerm_subnet" "vnetsubnetNet" {
  name                 = "toprefunderSubnet"
  resource_group_name  = var.resourceGroup
  virtual_network_name = var.virtualNetwork
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"] # used by storage containers
}
# Nat Gateway Public IP
resource "azurerm_public_ip" "natgatewayip" {
  name = "natgatewayIP"
  resource_group_name = var.resourceGroup
  location = var.location
  allocation_method = "Static"
  sku = "Standard"
}
#NAT gateway
resource "azurerm_nat_gateway" "natgateway" {
  name                = "example-natgateway"
  location            = var.location
  resource_group_name = var.resourceGroup
  
}
#Natgateway Public IP Association
resource "azurerm_nat_gateway_public_ip_association" "natgatewaypublicipasso" {
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
  public_ip_address_id = azurerm_public_ip.natgatewayip.id
}
# natgateway Subnet Association
resource "azurerm_subnet_nat_gateway_association" "natateway-subnet-assco" {
  subnet_id      = azurerm_subnet.vnetsubnetNet.id
  nat_gateway_id = azurerm_nat_gateway.natgateway.id
}
# Vnet Subnet NSG
resource "azurerm_network_security_group" "VnetSubnetSG" {
  name                = "toprefundNetworkSG"
  location            = var.location
  resource_group_name = var.resourceGroup

  security_rule {
    name                       = "toprefundSecurityRules"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
# Associate NSG to Subnet
resource "azurerm_subnet_network_security_group_association" "SGAssociation" {
  subnet_id                 = azurerm_subnet.vnetsubnetNet.id
  network_security_group_id = azurerm_network_security_group.VnetSubnetSG.id
}
# Subnet for Azure Bastion
resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"  # Must be exactly 'AzureBastionSubnet'
  resource_group_name  = var.resourceGroup
  virtual_network_name = var.virtualNetwork
  address_prefixes     = ["10.0.7.0/24"]
}
# Bastion Public IP
resource "azurerm_public_ip" "bastionip" {
  name                = "bastionpublicip"
  location            = var.location
  resource_group_name = var.resourceGroup
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Bastion
resource "azurerm_bastion_host" "bastion" {
  name                = "examplebastion"
  location            = var.location
  resource_group_name = var.resourceGroup

  ip_configuration {
    name                 = "bastionipconfig"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastionip.id
  }
}
# resource "azurerm_firewall" "example" {
#   name                = "testfirewall"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.example.id
#     public_ip_address_id = azurerm_public_ip.example.id
#   }
# }