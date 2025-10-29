variable "cluster_domain" {
  type        = string
  description = "Full apps domain for wildcard certificate (e.g., apps.ocp.example.com)"
}

variable "cluster_base_domain" {
  type        = string
  description = "Base cluster domain (e.g., ocp.example.com)"
}

variable "dns_zone_ocid" {
  type        = string
  description = "OCI DNS Zone OCID for DNS-01 challenge. Leave empty to skip TLS certificate setup."
  default     = ""
}

variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID where DNS zone and cluster exist"
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address for Let's Encrypt account registration and notifications"
}

variable "webhook_group_name" {
  type        = string
  description = "API group name for the OCI DNS webhook"
  default     = "acme.oci.oraclecloud.com"
}
