# ── ONS Notification Topic ────────────────────────────────────────────────────

resource "oci_ons_notification_topic" "security_alerts" {
  compartment_id = var.compartment_ocid
  name           = "${var.cluster_name}-alerts"
  description    = "Security and infrastructure alerts for OpenShift cluster ${var.cluster_name}"

  defined_tags = var.defined_tags
}

# ── ONS Subscriptions ─────────────────────────────────────────────────────────

resource "oci_ons_subscription" "webhook" {
  count = var.alert_webhook_url != "" ? 1 : 0

  compartment_id = var.compartment_ocid
  topic_id       = oci_ons_notification_topic.security_alerts.id
  protocol       = "HTTPS"
  endpoint       = var.alert_webhook_url

  defined_tags = var.defined_tags

  # Webhook subscriptions also go through a confirmation step (OCI sends a POST and
  # expects a 200 response). Ignore post-creation changes for the same reason.
  lifecycle {
    ignore_changes = all
  }
}

resource "oci_ons_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  compartment_id = var.compartment_ocid
  topic_id       = oci_ons_notification_topic.security_alerts.id
  protocol       = "EMAIL"
  endpoint       = var.alert_email

  defined_tags = var.defined_tags

  # OCI sends a confirmation email; subscription state changes externally.
  lifecycle {
    ignore_changes = all
  }
}

# ── OCI Monitoring Alarms ─────────────────────────────────────────────────────

# WAF block rate spike — fires when >50 requests/5 min are blocked (Layer 7 mode).
# Only created when WAF is enabled (waf_id provided).
resource "oci_monitoring_alarm" "waf_block_rate" {
  count = var.enable_waf ? 1 : 0

  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-waf-block-spike"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_waf"
  query                 = "BlockedRequests[5m].rate() > 50"
  severity              = "CRITICAL"
  body                  = "WAF is blocking an unusual number of requests on cluster ${var.cluster_name}. This may indicate a DDoS or brute-force attack."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}

# LB unhealthy backend — fires when any LB backend reports as unhealthy.
resource "oci_monitoring_alarm" "lb_unhealthy_backend" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-lb-unhealthy-backend"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_lbaas"
  query                 = "UnHealthyBackendCount[1m].max() > 0"
  severity              = "CRITICAL"
  body                  = "One or more backends on the apps or API load balancer for cluster ${var.cluster_name} are unhealthy. OpenShift traffic may be impacted."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}

# API LB 4xx spike — fires when the API LB receives >100 4xx responses/5 min.
resource "oci_monitoring_alarm" "api_4xx_spike" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-api-4xx-spike"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_lbaas"
  query                 = "HttpResponses[5m]{httpStatusCode = \"4xx\", loadBalancerId = \"${var.api_lb_id}\"}.rate() > 100"
  severity              = "WARNING"
  body                  = "The API load balancer for cluster ${var.cluster_name} is receiving an elevated rate of 4xx responses. This may indicate authentication issues or an attack."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}

# Compute CPU sustained — fires when average CPU exceeds 90% for 15 minutes.
resource "oci_monitoring_alarm" "cpu_high" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-cpu-high"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_computeagent"
  query                 = "CpuUtilization[15m]{compartmentId = \"${var.compartment_ocid}\"}.mean() > 90"
  severity              = "WARNING"
  body                  = "Average CPU utilisation in the ${var.cluster_name} cluster compartment has exceeded 90% for 15 minutes. Consider scaling compute nodes."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}

# Memory utilization — fires when average memory exceeds 85% for 15 minutes.
# High sustained memory leads to OOM kills and etcd instability.
resource "oci_monitoring_alarm" "memory_high" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-memory-high"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_computeagent"
  query                 = "MemoryUtilization[15m]{compartmentId = \"${var.compartment_ocid}\"}.mean() > 85"
  severity              = "WARNING"
  body                  = "Average memory utilisation in the ${var.cluster_name} cluster compartment has exceeded 85% for 15 minutes. Risk of OOM kills on pods or etcd."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}

# Disk utilization — fires when filesystem usage exceeds 80% for 10 minutes.
# OpenShift nodes become read-only when / or /var fills to eviction threshold (85%).
resource "oci_monitoring_alarm" "disk_high" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-disk-high"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_computeagent"
  query                 = "FilesystemUtilization[10m]{compartmentId = \"${var.compartment_ocid}\"}.max() > 80"
  severity              = "CRITICAL"
  body                  = "Filesystem utilisation on a node in the ${var.cluster_name} cluster compartment has exceeded 80%. OpenShift evicts pods and marks the node DiskPressure at 85%."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}

# Instance reachability — fires when the OCI Compute agent loses contact with an instance.
# This indicates a node crash or unresponsive OS before Kubernetes marks it NotReady.
resource "oci_monitoring_alarm" "instance_unreachable" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.cluster_name}-instance-unreachable"
  destinations          = [oci_ons_notification_topic.security_alerts.id]
  is_enabled            = true
  metric_compartment_id = var.compartment_ocid
  namespace             = "oci_compute_infrastructure_health"
  query                 = "instance_status[1m]{compartmentId = \"${var.compartment_ocid}\"}.sum() < 1"
  severity              = "CRITICAL"
  body                  = "An instance in the ${var.cluster_name} cluster compartment has become unreachable according to OCI infrastructure health checks. This may indicate a node crash or hardware failure."
  message_format        = "ONS_OPTIMIZED"

  defined_tags = var.defined_tags
}
