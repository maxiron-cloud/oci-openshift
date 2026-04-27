output "log_group_id" {
  value       = oci_logging_log_group.cluster_log_group.id
  description = "OCID of the cluster log group."
}
