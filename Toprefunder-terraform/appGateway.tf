
# resource "azurerm_subnet" "appGateSubnet" {
#   name                 = "appGatewaySubnet"
#   resource_group_name  = var.resourceGroup
#   virtual_network_name = var.virtualNetwork
#   address_prefixes     = ["10.0.3.0/24"]
# }

# resource "azurerm_public_ip" "appGatewayPublicIP" {
#   name                = "appGatewayIP"
#   resource_group_name = var.resourceGroup
#   location            = var.location
#   allocation_method   = "Static"
# }

# resource "azurerm_application_gateway" "appGateway" {
#   name                = var.applicationGateway
#   resource_group_name = var.resourceGroup
#   location            = var.location

#   sku {
#     name     = "Standard_v2"
#     tier     = "Standard_v2"
#     capacity = 2
#     zones = ["1"]
#   }

#   gateway_ip_configuration {
#     name      = "gatewayIPConfig"
#     subnet_id = azurerm_subnet.appGateSubnet.id
#   }

#   frontend_ip_configuration {
#     name                 = local.frontend_ip_config
#     public_ip_address_id = azurerm_public_ip.appGatewayPublicIP.id
#   }

#   frontend_port {
#     name = local.frontend_port
#     port = 80
#   }

#   frontend_port {
#     name = local.frontend_port
#     port = 443
#   }

#   backend_address_pool {
#     name = local.backend_address_pool

#     backend_address {
#       ip_address = azurerm_windows_virtual_machine_scale_set.VMSS.network_interface[0].private_ip_address
#     }
#   }

#   backend_http_settings {
#     name                  = local.http_setting
#     cookie_based_affinity = "Disabled"
#     path                  = "/path1/"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 60
#   }

#   backend_http_settings {
#     name                  = local.http_setting
#     cookie_based_affinity = "Disabled"
#     path                  = "/path1/"
#     port                  = 443
#     protocol              = "Https"
#     request_timeout       = 60
#   }

#   http_listener {
#     name                           = local.listener
#     frontend_ip_configuration_name = local.frontend_ip_config
#     frontend_port_name             = local.frontend_port
#     protocol                       = "Http"
#   }

#   http_listener {
#     name                           = "https-listener"
#     frontend_ip_configuration_name = local.frontend_ip_config
#     frontend_port_name             = "https-port"
#     protocol                       = "Https"
#     ssl_certificate_name           = "my-ssl-cert"
#   }

#   redirect_configuration {
#     name                  = local.redirect_configuration
#     redirect_type         = "Permanent"
#     target_listener_name  = "https-listener"
#   }

#   request_routing_rule {
#     name                       = local.request_routing_rule
#     priority                   = 9
#     rule_type                  = "Basic"
#     http_listener_name         = local.listener
#     backend_address_pool_name  = local.backend_address_pool
#     backend_http_settings_name = local.http_setting
#   }
# }
