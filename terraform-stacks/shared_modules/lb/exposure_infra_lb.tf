# Public exposure shard LB (WAAS origin) when dedicated infra nodes are provisioned.
# Fronts HostNetwork ingress on infra nodes; lifecycle is Terraform-owned (not CCM).

resource "oci_load_balancer_load_balancer" "openshift_exposure_infra_lb" {
  count                      = var.infra_count > 0 ? 1 : 0
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_exposure_infra_lb"
  shape                      = "flexible"
  subnet_ids                 = [var.op_subnet_public]
  is_private                 = false
  network_security_group_ids = [local.exposure_infra_lb_nsg_id]
  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
  defined_tags = var.defined_tags
}

locals {
  exposure_infra_lb_nsg_id = var.op_apps_public_lb_nsg_id != "" ? var.op_apps_public_lb_nsg_id : var.op_network_security_group_cluster_lb_nsg
}

resource "oci_load_balancer_backend_set" "openshift_exposure_infra_http_backend_set" {
  count = var.infra_count > 0 ? 1 : 0
  health_checker {
    protocol          = "TCP"
    port              = 80
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_exposure_infra_http"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_exposure_infra_lb[0].id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_exposure_infra_http" {
  count                    = var.infra_count > 0 ? 1 : 0
  default_backend_set_name = oci_load_balancer_backend_set.openshift_exposure_infra_http_backend_set[0].name
  name                     = "openshift_exposure_infra_http"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_exposure_infra_lb[0].id
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_exposure_infra_https_backend_set" {
  count = var.infra_count > 0 ? 1 : 0
  health_checker {
    protocol          = "TCP"
    port              = 443
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_exposure_infra_https"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_exposure_infra_lb[0].id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_exposure_infra_https" {
  count                    = var.infra_count > 0 ? 1 : 0
  default_backend_set_name = oci_load_balancer_backend_set.openshift_exposure_infra_https_backend_set[0].name
  name                     = "openshift_exposure_infra_https"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_exposure_infra_lb[0].id
  port                     = 443
  protocol                 = "TCP"
}
