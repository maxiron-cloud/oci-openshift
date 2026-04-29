output "policy_id" {
  description = "OCID of the assigned OCI-managed backup policy (null when backup is disabled)."
  value       = var.enable_boot_volume_backup ? local.policy_id : null
}

output "assignment_ids" {
  description = "Map of boot volume index → backup policy assignment OCID."
  value       = { for k, v in oci_core_volume_backup_policy_assignment.boot_volume : k => v.id }
}
