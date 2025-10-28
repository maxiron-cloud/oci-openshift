output "cluster_issuer_name" {
  description = "Name of the ClusterIssuer resource"
  value       = local.enable_tls ? "letsencrypt-prod" : "N/A - DNS zone not found"
}

output "certificate_secret_name" {
  description = "Name of the Secret containing the wildcard TLS certificate"
  value       = local.enable_tls ? "wildcard-tls-cert" : "N/A - DNS zone not found"
}

output "cert_manager_namespace" {
  description = "Namespace where cert-manager is installed"
  value       = local.enable_tls ? kubernetes_namespace_v1.cert_manager[0].metadata[0].name : "N/A - DNS zone not found"
}

