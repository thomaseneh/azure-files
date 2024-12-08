terraform {
  required_providers {
    azurerm = {
      version = ">=4.9.0"
    }
  }
}
provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
}

data "azurerm_resource_group" "resourceGroup" {
  name = "demoResourceG"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "demoAKS"
  resource_group_name = data.azurerm_resource_group.resourceGroup.name
  location            = data.azurerm_resource_group.resourceGroup.location
  dns_prefix          = "aksDNS"
  kubernetes_version  = "1.29.9"

  default_node_pool {
    name                 = "demonode"
    os_sku               = "Ubuntu"
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3
    max_pods             = 120
    vm_size              = "Standard_D4s_v3"
    zones                = ["1", "3"]
    os_disk_type         = "Managed"
  }
  #   auto_upgrade_profile {
  #     upgrade_channel = "patch"
  #   }

  identity {
    type = "SystemAssigned"
  }

  # Specify a custom node resource group
  node_resource_group = "MC_Resource-Group"

  network_profile {
    network_plugin = "azure"
    # network_policy = "none" 
  }
  # Enable OIDC and Workload Identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [6]
    }
  }

  # Enable Image Cleaner
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 720

  tags = {
    Environment = "Dev/Test"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "reactapp" {
  metadata {
    name = "reactapp"
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
