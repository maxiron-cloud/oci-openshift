variable "kubeconfig_par_url" {
  type        = string
  description = "Pre-Authenticated Request (PAR) URL to fetch kubeconfig from OCI Object Storage. Upload your kubeconfig to Object Storage and create a PAR URL."
}

variable "image_registry_storage_size" {
  type        = string
  description = "Size of PVC for image registry (e.g., 100Gi, 200Gi)"
  default     = "100Gi"
}

variable "image_registry_storage_class" {
  type        = string
  description = "StorageClass for image registry PVC"
  default     = "oci-bv-immediate"
}

variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID where cluster resources exist (used for DNS zone lookup)"
}

variable "dns_compartment_ocid" {
  type        = string
  description = "Compartment OCID where DNS zone exists. Leave empty to use the same compartment as specified in compartment_ocid."
  default     = ""
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address for Let's Encrypt account notifications and certificate expiry alerts"
  default     = "cloud@maxiron.com"
}

