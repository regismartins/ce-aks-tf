resource "azurerm_resource_group" "resource_group" {
  name     = "${var.owner-name}-${var.prefix}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.owner-name}-${var.prefix}-cluster"
  location            = var.location
  resource_group_name = "${var.owner-name}-${var.prefix}-rg"
  dns_prefix          = "${var.owner-name}aks"
  kubernetes_version  = var.kubernetes_version
  depends_on = [
    azurerm_resource_group.resource_group
  ]
  provisioner "local-exec" {
    command = <<-EOT
              az aks get-credentials -g ${azurerm_resource_group.resource_group.name} -n ${azurerm_kubernetes_cluster.cluster.name} --overwrite-existing
    EOT
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    network_mode   = "transparent"
  }

  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name                  = "default"
    node_count            = 2
    max_pods              = 110
    enable_node_public_ip = true
    vm_size               = var.vm-size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    owner       = var.owner-name
    environment = "Calico Enterprise Trial"
  }
}