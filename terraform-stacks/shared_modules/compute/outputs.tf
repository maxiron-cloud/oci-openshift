output "cp_boot_volume_ids" {
  description = "List of boot volume OCIDs for all control-plane nodes."
  value       = [for k, v in local.control_plane_instances : v.boot_volume_id]
}

output "compute_boot_volume_ids" {
  description = "List of boot volume OCIDs for all compute/worker nodes."
  value       = [for k, v in oci_core_instance.compute_node : v.boot_volume_id]
}

output "infra_boot_volume_ids" {
  description = "List of boot volume OCIDs for all infra nodes."
  value       = [for k, v in oci_core_instance.infra_node : v.boot_volume_id]
}
