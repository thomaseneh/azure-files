# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "test"
  location            = var.location
  resource_group_name = var.resourceGroup
  allocation_method   = "Static"
  domain_name_label   = "toprefunderdnsname"

  tags = {
    environment = "staging"
  }
}

# Load Balancer
resource "azurerm_lb" "loadbalancer" {
  name                = "test"
  location            = var.location
  resource_group_name = var.resourceGroup

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "backendpool" {
  loadbalancer_id = azurerm_lb.loadbalancer.id
  name            = "BackdsPool"
}

# Health Probe
resource "azurerm_lb_probe" "healthprobe" {
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = "lbProbe"
  protocol            = "Tcp"
  port                = 8080 # must match the backend port the application is running on
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancing Rule
resource "azurerm_lb_rule" "lbrule" {
  loadbalancer_id                = azurerm_lb.loadbalancer.id
  name                           = "lbRule"
  protocol                       = "Tcp"
  frontend_port                  = 80 # if my javascript application runs on port 80
  backend_port                   = 8080 # if my java backend application runs on port 8080
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backendpool.id]
  probe_id                       = azurerm_lb_probe.healthprobe.id
  idle_timeout_in_minutes        = 4
  enable_floating_ip             = false
}

# Virtual Machine Scale Set with Windows Server 2022
resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "toprefundervmss"
  location            = var.location
  resource_group_name = var.resourceGroup

  # Automatic rolling upgrade
  automatic_os_upgrade = true
  upgrade_policy_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = azurerm_lb_probe.healthprobe.id

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  storage_profile_os_disk {
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "testvm"
    admin_username       = "myadmin"
    admin_password       = "myP@ssw0rd123!"  # Windows VM password (use a secure password)
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.vnetsubnetNet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backendpool.id]
    }
  }

  tags = {
    environment = "staging"
  }
}
