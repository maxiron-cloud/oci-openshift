# Fetch kubeconfig from Object Storage using PAR URL
data "http" "kubeconfig" {
  url = var.kubeconfig_par_url
}

locals {
  # Auto-detect cluster domain from kubeconfig
  kubeconfig_data     = yamldecode(data.http.kubeconfig.response_body)
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

# Kubernetes provider configuration - use config content directly to avoid file dependency
provider "kubernetes" {
  host                   = local.kubeconfig_data.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig_data.clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig_data.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig_data.users[0].user["client-key-data"])
}

# Kubectl provider configuration - use config content directly
provider "kubectl" {
  host                   = local.kubeconfig_data.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig_data.clusters[0].cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.kubeconfig_data.users[0].user["client-certificate-data"])
  client_key             = base64decode(local.kubeconfig_data.users[0].user["client-key-data"])
  load_config_file       = false
}

# Lookup DNS zone OCID from provided zone name
data "oci_dns_zones" "cluster_zone" {
  count          = var.dns_zone_name != "" ? 1 : 0
  compartment_id = local.dns_compartment
  name           = var.dns_zone_name
  scope          = "GLOBAL"
}

locals {
  dns_zone_id = var.dns_zone_name != "" && length(data.oci_dns_zones.cluster_zone) > 0 && length(data.oci_dns_zones.cluster_zone[0].zones) > 0 ? data.oci_dns_zones.cluster_zone[0].zones[0].id : ""
}

module "image_registry" {
  source = "./modules/image-registry"

  storage_size  = var.image_registry_storage_size
  storage_class = var.image_registry_storage_class
}

module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_domain        = local.apps_domain
  dns_zone_ocid        = local.dns_zone_id
  dns_compartment_ocid = local.dns_compartment
  letsencrypt_email    = var.letsencrypt_email

  depends_on = [module.image_registry]
}

