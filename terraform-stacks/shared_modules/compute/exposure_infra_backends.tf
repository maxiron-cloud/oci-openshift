# Backends for the Terraform-managed public exposure LB (infra-node lbMode).

resource "oci_load_balancer_backend" "openshift_exposure_infra_https_backend_set_backends" {
  for_each         = var.create_openshift_instances && var.op_lb_openshift_exposure_infra_lb != "" ? var.infra_node_map : {}
  load_balancer_id = var.op_lb_openshift_exposure_infra_lb
  backendset_name  = var.op_lb_bs_openshift_exposure_infra_https_backend_set
  port             = 443
  ip_address       = data.oci_core_vnic.infra_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_exposure_infra_http_backend_set_backends" {
  for_each         = var.create_openshift_instances && var.op_lb_openshift_exposure_infra_lb != "" ? var.infra_node_map : {}
  load_balancer_id = var.op_lb_openshift_exposure_infra_lb
  backendset_name  = var.op_lb_bs_openshift_exposure_infra_http_backend_set
  port             = 80
  ip_address       = data.oci_core_vnic.infra_primary_vnic[each.key].private_ip_address
}
