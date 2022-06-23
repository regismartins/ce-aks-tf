resource "null_resource" "collect-secrets" {
  depends_on = [
    null_resource.online-boutique
  ]
  provisioner "local-exec" {
    command = <<-EOT
            until (kubectl get service frontend-external -o=jsonpath='{.status.loadBalancer.ingress[*].ip}' | grep .)
            do
            sleep 5
            echo "waiting for the application loadbalancer to come up"
            done
            echo "Online Boutique Portal: " > ../tigera-secrets/secrets.txt
            echo "url: http://$(kubectl get service frontend-external -o=jsonpath='{.status.loadBalancer.ingress[*].ip}')/ \n" >> ../tigera-secrets/secrets.txt
            echo "-------------------------------------------------" >> ../tigera-secrets/secrets.txt
            echo "Calico Portal: " >> ../tigera-secrets/secrets.txt
            echo "url: https://${kubernetes_service.loadbalancer.status[0].load_balancer[0].ingress[0].ip}:9443/" >> ../tigera-secrets/secrets.txt
            echo "token : $(kubectl get secret ${kubernetes_service_account.service-account.default_secret_name} -o go-template='{{.data.token | base64decode}}') \n" >> ../tigera-secrets/secrets.txt
            echo "-------------------------------------------------" >> ../tigera-secrets/secrets.txt
            echo "kibana" >> ../tigera-secrets/secrets.txt
            echo "username: elastic" >> ../tigera-secrets/secrets.txt
            echo "password: $(kubectl -n tigera-elasticsearch get secret tigera-secure-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')" >> ../tigera-secrets/secrets.txt
            cat ../tigera-secrets/secrets.txt
    EOT
  }
}

output "calico_portal" {
  value = "Environment information can be find at ../tigera-secrets/secrets.txt"
}
