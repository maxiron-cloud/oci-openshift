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

variable "op_subnet_public_api" {
  type        = string
  description = "Public subnet for external API LB (defaults to op_subnet_public when empty)."
  default     = ""
}

variable "op_network_security_group_cluster_lb_nsg" {
  type = string
}

variable "infra_count" {
  type        = number
  default     = 0
  description = "When > 0, provision the Terraform-managed public exposure infra LB."
}

variable "op_apps_public_lb_nsg_id" {
  type        = string
  default     = ""
  description = "APPS-PUBLIC NSG for the exposure infra LB (landing-zone bundle). Falls back to cluster LB NSG when empty."
}

