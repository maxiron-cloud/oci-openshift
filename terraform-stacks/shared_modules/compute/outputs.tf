output "cp_boot_volume_ids" {
  description = "List of boot volume OCIDs for all control-plane nodes."
  value       = [for k, v in oci_core_instance.control_plane_node : v.boot_volume_id]
}

output "compute_boot_volume_ids" {
  description = "List of boot volume OCIDs for all compute/worker nodes."
  value       = [for k, v in oci_core_instance.compute_node : v.boot_volume_id]
}
