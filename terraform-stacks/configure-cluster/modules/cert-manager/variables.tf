variable "cluster_domain" {
  type        = string
  description = "Cluster domain for wildcard certificate (e.g., apps.ocp.example.com)"
}

variable "dns_zone_ocid" {
  type        = string
  description = "OCI DNS Zone OCID for DNS-01 challenge. Leave empty to skip TLS certificate setup."
  default     = ""
}

variable "dns_compartment_ocid" {
  type        = string
  description = "Compartment OCID where DNS zone exists"
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address for Let's Encrypt account registration and notifications"
}

variable "cert_manager_version" {
  type        = string
  description = "cert-manager version to install"
  default     = "v1.16.2"
}

variable "oci_dns_webhook_version" {
  type        = string
  description = "cert-manager-webhook-oci version"
  default     = "0.3.0"
}

