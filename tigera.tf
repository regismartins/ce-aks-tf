// Configure a storage class for Calico Enterprise

resource "kubernetes_storage_class" "tigera_storage_class" {

  depends_on = [
    azurerm_kubernetes_cluster.cluster
  ]

  metadata {
    name = "tigera-elasticsearch"
  }

  storage_provisioner    = "kubernetes.io/azure-disk"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    cachingmode        = "ReadOnly"
    kind               = "Managed"
    storageaccounttype = "StandardSSD_LRS"
  }
}

// Install Calico Enterprise

resource "null_resource" "tigera-installation" {
  depends_on = [
    kubernetes_storage_class.tigera_storage_class
  ]
  provisioner "local-exec" {
    command = <<-EOT
              kubectl create -f https://docs.tigera.io/manifests/tigera-operator.yaml
              kubectl create -f https://docs.tigera.io/manifests/tigera-prometheus-operator.yaml
              kubectl create secret generic tigera-pull-secret \
                --type=kubernetes.io/dockerconfigjson -n tigera-operator \
                --from-file=.dockerconfigjson=../tigera-secrets/config.json
              kubectl create secret generic tigera-pull-secret \
                --type=kubernetes.io/dockerconfigjson -n tigera-prometheus \
                --from-file=.dockerconfigjson=../tigera-secrets/config.json
              kubectl patch deployment -n tigera-prometheus calico-prometheus-operator \
                -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name": "tigera-pull-secret"}]}}}}'
              kubectl create -f https://docs.tigera.io/manifests/aks/custom-resources.yaml
              until (kubectl get tigerastatus -o=jsonpath="{.items[?(.metadata.name=='apiserver')].status.conditions[?(@.type=='Degraded')].status}" | grep False)
              do
              sleep 10
              done
    EOT
  }
}

// Install the Calico Enterprise license

resource "null_resource" "tigera-license" {
  depends_on = [
    null_resource.tigera-installation
  ]
  provisioner "local-exec" {
    command = <<-EOT
              until (kubectl get licensekey -o=jsonpath="{.items[*].metadata.name}" | grep default)
              do 
              kubectl create -f ../tigera-secrets/license.yaml
              sleep 10
              done
              while (kubectl get tigerastatus -o=jsonpath="{.items[*].status.conditions[?(.type=='Degraded')].status}" |  grep True)
              do
              sleep 10
              done
              sleep 30
    EOT
  }
}

// Secure Calico Enterprise with network policy 

resource "null_resource" "tigera-network-policy" {
  depends_on = [
    null_resource.tigera-license
  ]
  provisioner "local-exec" {
    command = "kubectl create -f https://docs.tigera.io/manifests/tigera-policies.yaml"
  }
}

// Configure your cluster with a service load balancer 
// controller to implement the external load balancer

resource "kubernetes_service" "loadbalancer" {
  depends_on = [
    null_resource.tigera-network-policy
  ]
  metadata {
    name      = "tigera-manager-external"
    namespace = "tigera-manager"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      k8s-app = "tigera-manager"
    }
    external_traffic_policy = "Local"
    port {
      port        = 9443
      target_port = 9443
      protocol    = "TCP"
    }
  }
}

// Log in to Calico Enterprise Manager

resource "kubernetes_service_account" "service-account" {
  depends_on = [
    kubernetes_service.loadbalancer
  ]

  metadata {
    name = var.owner-name
  }
}

resource "kubernetes_cluster_role_binding" "cluster-role-binding" {

  depends_on = [
    kubernetes_service_account.service-account
  ]

  metadata {
    name = "${var.owner-name}-access"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "tigera-network-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.owner-name
    namespace = "default"
  }
}
