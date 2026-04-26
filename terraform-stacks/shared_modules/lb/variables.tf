variable "enable_public_apps_lb" {
  type = bool
}

variable "enable_public_api_lb" {
  type = bool
}

variable "compartment_ocid" {
  type = string
}

variable "load_balancer_shape_details_maximum_bandwidth_in_mbps" {
  type = number
}

variable "load_balancer_shape_details_minimum_bandwidth_in_mbps" {
  type = number
}

variable "cluster_name" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}

variable "op_subnet_private_ocp" {
  type = string
}

variable "op_subnet_public" {
  type = string
}

variable "op_network_security_group_cluster_lb_nsg" {
  type = string
}

# Optional SSL termination — when set, the apps LB listens on 443 with this Sectigo/custom cert.
# Users will see this certificate in their browser. Leave empty for TCP passthrough (default).

variable "ssl_certificate_pem" {
  type        = string
  description = "PEM content of the public leaf certificate (e.g. STAR_maxiron_cloud / cert.pem). Required when enabling SSL termination."
  default     = ""
  sensitive   = false
}

variable "ssl_certificate_chain_pem" {
  type        = string
  description = "PEM content of the CA chain bundle (e.g. My_CA_Bundle / chain.pem). Required when enabling SSL termination."
  default     = ""
  sensitive   = false
}

variable "ssl_private_key_pem" {
  type        = string
  description = "PEM content of the private key matching the certificate. Required when enabling SSL termination."
  default     = ""
  sensitive   = true
}
