variable "enable_boot_volume_backup" {
  type        = bool
  default     = false
  description = "Assign an OCI-managed backup policy to all cluster boot volumes."
}

variable "boot_volume_backup_policy" {
  type        = string
  default     = "gold"
  description = "OCI-managed backup policy to assign. One of: bronze, silver, gold."

  validation {
    condition     = contains(["bronze", "silver", "gold"], var.boot_volume_backup_policy)
    error_message = "boot_volume_backup_policy must be one of: bronze, silver, gold."
  }
}

variable "cp_boot_volume_ids" {
  type        = list(string)
  default     = []
  description = "Boot volume OCIDs for control-plane nodes (from module.compute.cp_boot_volume_ids)."
}

variable "compute_boot_volume_ids" {
  type        = list(string)
  default     = []
  description = "Boot volume OCIDs for compute/worker nodes (from module.compute.compute_boot_volume_ids)."
}
