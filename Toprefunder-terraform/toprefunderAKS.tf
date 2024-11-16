
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "toprefunder_aks1"
  location            = var.location
  resource_group_name = var.resourceGroup
  dns_prefix          = "toprefunderdns1"

  default_node_pool {
    name       = "refundecrnod"
    os_sku = "Ubuntu"
    auto_scaling_enabled = true
    min_count = 1
    max_count = 3
    max_pods = 120
    vm_size    = "Standard_D4s_v3"
    zones = ["1","3"]
    os_disk_type        = "Managed"
  }
#   auto_upgrade_profile {
#     upgrade_channel = "patch"
#   }

  network_profile {
    network_plugin = "azure"
    # network_policy = "none" 
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw

  sensitive = true
}