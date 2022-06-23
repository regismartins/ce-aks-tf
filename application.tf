resource "null_resource" "online-boutique" {
  depends_on = [
    kubernetes_cluster_role_binding.cluster-role-binding
  ]
  provisioner "local-exec" {
    command = <<-EOT
              git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
              cd microservices-demo
              kubectl apply -f ./release/kubernetes-manifests.yaml
    EOT
  }
}