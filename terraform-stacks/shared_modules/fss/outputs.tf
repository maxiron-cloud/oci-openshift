# ============================================================================
# FSS Module Outputs
# ============================================================================

output "file_system_id" {
  description = "OCID of the created file system"
  value       = oci_file_storage_file_system.cluster_fss.id
}

output "mount_target_id" {
  description = "OCID of the created mount target"
  value       = oci_file_storage_mount_target.cluster_mount_target.id
}

output "export_set_id" {
  description = "OCID of the export set associated with the mount target"
  value       = oci_file_storage_mount_target.cluster_mount_target.export_set_id
}

output "export_path" {
  description = "Export path for NFS mounts"
  value       = oci_file_storage_export.cluster_export.path
}

output "mount_target_ip" {
  description = "Private IP address of the mount target for NFS mounts"
  value       = oci_file_storage_mount_target.cluster_mount_target.private_ip_ids[0]
}

output "mount_target_hostname" {
  description = "Hostname of the mount target"
  value       = oci_file_storage_mount_target.cluster_mount_target.hostname_label
}

