resource "oci_logging_log_group" "cluster_log_group" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-logs"
  description    = "Access and WAF logs for OpenShift cluster ${var.cluster_name}"

  defined_tags = var.defined_tags
}

resource "oci_logging_log" "apps_lb_access" {
  display_name = "apps-lb-access"
  log_group_id = oci_logging_log_group.cluster_log_group.id
  log_type     = "SERVICE"
  is_enabled   = true

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
  display_name = "apps-lb-error"
  log_group_id = oci_logging_log_group.cluster_log_group.id
  log_type     = "SERVICE"
  is_enabled   = true

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
  display_name = "api-lb-access"
  log_group_id = oci_logging_log_group.cluster_log_group.id
  log_type     = "SERVICE"
  is_enabled   = true

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
  count = var.waf_id != "" ? 1 : 0

  display_name = "apps-waf-log"
  log_group_id = oci_logging_log_group.cluster_log_group.id
  log_type     = "SERVICE"
  is_enabled   = true

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
