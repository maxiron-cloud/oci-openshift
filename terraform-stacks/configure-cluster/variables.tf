variable "kubeconfig_content" {
  type        = string
  description = "Content of the kubeconfig file. Paste the complete content of your kubeconfig file here."
  sensitive   = true
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

