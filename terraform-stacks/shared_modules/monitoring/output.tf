output "notification_topic_id" {
  description = "OCID of the ONS notification topic that receives all cluster alarms."
  value       = oci_ons_notification_topic.security_alerts.id
}

output "notification_topic_name" {
  description = "Display name of the ONS notification topic."
  value       = oci_ons_notification_topic.security_alerts.name
}
