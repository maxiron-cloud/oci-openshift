variable "compartment_ocid" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "enable_bastion" {
  type    = bool
  default = false
}

variable "target_subnet_id" {
  type        = string
  description = "OCID of the private OCP subnet where the Bastion will be provisioned."
}

variable "bastion_allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to initiate Bastion sessions."
  default     = ["0.0.0.0/0"]
}

variable "defined_tags" {
  type = map(string)
}
