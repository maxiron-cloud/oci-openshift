output "staging_cluster_issuer" {
  description = "Name of the Let's Encrypt staging ClusterIssuer"
  value       = local.enable_tls ? "letsencrypt-staging" : "N/A - DNS zone not provided"
}

output "production_cluster_issuer" {
  description = "Name of the Let's Encrypt production ClusterIssuer"
  value       = local.enable_tls ? "letsencrypt-prod" : "N/A - DNS zone not provided"
}

output "apps_certificate_secret" {
  description = "Name of the Secret containing the apps wildcard TLS certificate"
  value       = local.enable_tls ? "apps-wildcard-tls" : "N/A - DNS zone not provided"
}

output "api_certificate_secret" {
  description = "Name of the Secret containing the API server TLS certificate"
  value       = local.enable_tls ? "api-server-tls" : "N/A - DNS zone not provided"
}

output "cert_manager_namespace" {
  description = "Namespace where cert-manager operator is installed"
  value       = local.enable_tls ? "cert-manager-operator" : "N/A - DNS zone not provided"
}

output "webhook_namespace" {
  description = "Namespace where OCI DNS webhook is deployed"
  value       = local.enable_tls ? "cert-manager-webhook-oci" : "N/A - DNS zone not provided"
}
