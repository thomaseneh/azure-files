resource "azurerm_windows_virtual_machine_scale_set" "VMSS" {
  name                 = "toprefunderVMSS"
  resource_group_name  = var.resourceGroup
  location             = var.location
  sku                  = "Standard_B2s"
  instances            = 1
  admin_password      = "Mine@!23"
  # admin_password       = data.azurerm_key_vault_secret.storageKey.value
  admin_username       = "adminuser"
  computer_name_prefix = "vm-"
  zones = [ "1", "3" ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-Azure-edition"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "toprefunderNIC"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vnetsubnetNet.id
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "autoScale" {
  name                = "toprefunderVMSS-AutoscaleSetting"
  resource_group_name = var.resourceGroup
  location            = var.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.VMSS.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.VMSS.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.VMSS.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  predictive {
    scale_mode      = "Enabled"
    look_ahead_time = "PT5M"
  }

  notification {
    email {
      # custom_emails                         = ["admin@contoso.com"]
    }
  }
}