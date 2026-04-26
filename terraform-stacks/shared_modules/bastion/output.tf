output "bastion_id" {
  description = "OCID of the OCI Bastion (null when enable_bastion=false)."
  value       = length(oci_bastion_bastion.cluster_bastion) > 0 ? oci_bastion_bastion.cluster_bastion[0].id : null
}
