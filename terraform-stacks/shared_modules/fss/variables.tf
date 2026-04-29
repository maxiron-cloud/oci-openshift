# ============================================================================
# FSS Module Variables
# ============================================================================

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where FSS resources will be created"
}

variable "availability_domain" {
  type        = string
  description = "Availability domain for FSS file system and mount target (e.g., xgnN:UK-LONDON-1-AD-1)"
}

variable "subnet_ocid" {
  type        = string
  description = "OCID of the subnet where the mount target will be created (typically private_ocp subnet)"
}

variable "nsg_ocid" {
  type        = string
  description = "OCID of the network security group to attach to the mount target (typically cluster_compute NSG)"
}

variable "display_name_prefix" {
  type        = string
  description = "Prefix for resource display names (typically cluster name)"
}

variable "nfs_source_cidr" {
  type        = string
  description = "CIDR allowed to mount the FSS export. Defaults to the cluster VCN CIDR."
}

variable "encrypt_in_transit" {
  type        = bool
  description = "Enable encryption in transit for NFS connections"
  default     = false
}

variable "kms_key_id" {
  type        = string
  description = "Optional OCI Vault customer-managed key OCID for file system encryption. Empty string uses Oracle-managed keys."
  default     = ""
}

variable "defined_tags" {
  type        = map(string)
  description = "Defined tags for resource attribution"
  default     = {}
}

