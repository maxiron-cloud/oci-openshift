variable "use_existing_network" {
  type    = bool
  default = false
}

variable "existing_vcn_id" {
  type = string
}

variable "vcn_cidr" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "networking_compartment_ocid" {
  type = string
}

variable "vcn_dns_label" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "private_cidr_ocp" {
  type = string
}

variable "private_cidr_bare_metal" {
  type = string
}

variable "public_cidr" {
  type = string
}

variable "defined_tags" {
  type = map(string)
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

variable "allowed_api_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the OpenShift API on port 6443. Empty list allows all."
  default     = []
}

variable "allowed_apps_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach cluster applications on ports 80/443. Empty list allows all."
  default     = []
}
