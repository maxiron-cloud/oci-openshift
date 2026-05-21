variable "compartment_ocid" {
  type = string
}

variable "existing_vcn_id" {
  type = string
}

variable "existing_private_ocp_subnet_id" {
  type = string
}

variable "existing_private_bare_metal_subnet_id" {
  type = string
}

variable "existing_public_subnet_id" {
  type = string
}

variable "existing_lb_nsg_id" {
  type        = string
  description = "OCID of the landing-zone API/ingress NSG used for cluster load balancers. When set with control plane and compute NSG OCIDs, skips regex discovery and legacy security-list checks."
  default     = ""
}

variable "existing_controlplane_nsg_id" {
  type        = string
  description = "OCID of the landing-zone control plane NSG."
  default     = ""
}

variable "existing_compute_nsg_id" {
  type        = string
  description = "OCID of the landing-zone compute NSG."
  default     = ""
}
