output "cluster_issuer_name" {
  description = "Name of the ClusterIssuer resource"
  value       = "letsencrypt-prod"
}

output "certificate_secret_name" {
  description = "Name of the Secret containing the wildcard TLS certificate"
  value       = "wildcard-tls-cert"
}

output "cert_manager_namespace" {
  description = "Namespace where cert-manager is installed"
  value       = kubernetes_namespace_v1.cert_manager.metadata[0].name
}

