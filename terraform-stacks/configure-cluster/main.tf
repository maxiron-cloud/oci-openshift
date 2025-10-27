# Create local kubeconfig file from content
resource "local_file" "kubeconfig" {
  content  = var.kubeconfig_content
  filename = "${path.module}/kubeconfig"
}

locals {
  kubeconfig_path = local_file.kubeconfig.filename
  
  # Auto-detect cluster domain from kubeconfig
  kubeconfig_data     = yamldecode(var.kubeconfig_content)
  cluster_api_url     = local.kubeconfig_data.clusters[0].cluster.server
  # Extract base domain from API URL (e.g., https://api.ocp.example.com:6443 -> ocp.example.com)
  cluster_base_domain = replace(replace(local.cluster_api_url, "https://api.", ""), ":6443", "")
  # Apps domain for wildcard certificate
  apps_domain = "apps.${local.cluster_base_domain}"
  
  # DNS compartment (use provided or default to cluster compartment)
  dns_compartment = var.dns_compartment_ocid != "" ? var.dns_compartment_ocid : var.compartment_ocid
}

# OCI provider for DNS zone lookup
provider "oci" {
  # Uses OCI CLI or instance principal authentication
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "kubectl" {
  config_path = local.kubeconfig_path
}

# Auto-detect DNS zone OCID by looking up the zone that matches cluster base domain
data "oci_dns_zones" "cluster_zone" {
  compartment_id = local.dns_compartment
  name           = local.cluster_base_domain
  scope          = "GLOBAL"
}

module "image_registry" {
  source = "./modules/image-registry"

  storage_size  = var.image_registry_storage_size
  storage_class = var.image_registry_storage_class
}

module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_domain        = local.apps_domain
  dns_zone_ocid        = data.oci_dns_zones.cluster_zone.zones[0].id
  dns_compartment_ocid = local.dns_compartment
  letsencrypt_email    = var.letsencrypt_email

  depends_on = [module.image_registry]
}

