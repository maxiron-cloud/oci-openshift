resource "oci_logging_log_group" "cluster_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-logs"
  description    = "Access, WAF and session logs for OpenShift cluster ${var.cluster_name}"

  defined_tags = var.defined_tags
}

resource "oci_logging_log" "apps_lb_access" {
  display_name       = "apps-lb-access"
  log_group_id       = oci_logging_log_group.cluster_log_group.id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.log_retention_days
  defined_tags       = var.defined_tags

  configuration {
    source {
      category    = "access"
      resource    = var.apps_lb_id
      service     = "loadbalancer"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
}

resource "oci_logging_log" "apps_lb_error" {
  display_name       = "apps-lb-error"
  log_group_id       = oci_logging_log_group.cluster_log_group.id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.log_retention_days
  defined_tags       = var.defined_tags

  configuration {
    source {
      category    = "error"
      resource    = var.apps_lb_id
      service     = "loadbalancer"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
}

resource "oci_logging_log" "api_lb_access" {
  display_name       = "api-lb-access"
  log_group_id       = oci_logging_log_group.cluster_log_group.id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.log_retention_days
  defined_tags       = var.defined_tags

  configuration {
    source {
      category    = "access"
      resource    = var.api_lb_id
      service     = "loadbalancer"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
}

resource "oci_logging_log" "waf" {
  count = var.enable_waf ? 1 : 0

  display_name       = "apps-waf-log"
  log_group_id       = oci_logging_log_group.cluster_log_group.id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.log_retention_days
  defined_tags       = var.defined_tags

  configuration {
    source {
      category    = "all"
      resource    = var.waf_id
      service     = "waf"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
}

# ── VCN Flow Logs ─────────────────────────────────────────────────────────────
#
# OCI VCN flow logs capture TCP/UDP accept/reject decisions at the VCN level.
# Records include: src/dst IP, src/dst port, protocol, bytes, packets, action.
# These logs support ISO 27001 A.8.16 (network activity monitoring) and are
# invaluable for incident investigation and NSG rule tuning.
#
# Category "all" captures both ACCEPTED and REJECTED traffic.
# Cost: ~$0.0002/100k log entries. For a typical OpenShift cluster this is
# under $5/month even with active workloads.
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_logging_log" "vcn_flow" {
  count = var.enable_flow_logs ? 1 : 0

  display_name       = "vcn-flow-log"
  log_group_id       = oci_logging_log_group.cluster_log_group.id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.log_retention_days
  defined_tags       = var.defined_tags

  configuration {
    source {
      category    = "all"
      resource    = var.vcn_id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
    compartment_id = var.compartment_ocid
  }
}
