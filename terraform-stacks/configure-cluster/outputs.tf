output "image_registry_pvc_name" {
  description = "Name of the PVC created for the image registry"
  value       = module.image_registry.pvc_name
}

output "image_registry_storage_class" {
  description = "StorageClass used for the image registry"
  value       = var.image_registry_storage_class
}

output "image_registry_storage_size" {
  description = "Storage size allocated for the image registry"
  value       = var.image_registry_storage_size
}

output "stack_version" {
  value = local.stack_version
}

output "cluster_domain" {
  description = "Auto-detected cluster domain"
  value       = local.cluster_base_domain
}

output "apps_domain" {
  description = "Apps domain for wildcard certificate"
  value       = local.apps_domain
}

output "cert_manager_cluster_issuer" {
  description = "ClusterIssuer name for Let's Encrypt"
  value       = module.cert_manager.cluster_issuer_name
}

output "wildcard_certificate_secret" {
  description = "Secret name containing the wildcard TLS certificate"
  value       = module.cert_manager.certificate_secret_name
}

output "dns_zone_ocid" {
  description = "DNS zone OCID being used"
  value       = local.dns_zone_id != "" ? local.dns_zone_id : "N/A - dns_zone_name not provided"
}

output "dns_zone_name" {
  description = "DNS zone name provided"
  value       = var.dns_zone_name != "" ? var.dns_zone_name : "N/A - not provided"
}

