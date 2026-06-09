// Output the LB ids

output "op_lb_openshift_api_int_lb" {
  value = try(oci_load_balancer_load_balancer.openshift_api_int_lb.id, null)
}

output "op_lb_openshift_api_lb" {
  value = try(oci_load_balancer_load_balancer.openshift_api_lb.id, null)
}

output "op_lb_openshift_apps_lb" {
  value = try(oci_load_balancer_load_balancer.openshift_apps_lb.id, null)
}

// Output the IP addresses

output "op_lb_openshift_api_int_lb_ip_addr" {
  value = try(oci_load_balancer_load_balancer.openshift_api_int_lb.ip_address_details[0].ip_address, null)
}

output "op_lb_openshift_api_lb_ip_addr" {
  value = try(oci_load_balancer_load_balancer.openshift_api_lb.ip_address_details[0].ip_address, null)
}

output "op_lb_openshift_apps_lb_ip_addr" {
  value = try(oci_load_balancer_load_balancer.openshift_apps_lb.ip_address_details[0].ip_address, null)
}

// Output the backend set names

output "op_lb_bs_openshift_cluster_api_backend_set_external" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_api_backend_set_external.name, null)
}

output "op_lb_bs_openshift_cluster_ingress_http_backend_set" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend_set.name, null)
}

output "op_lb_bs_openshift_cluster_ingress_https_backend_set" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend_set.name, null)
}

output "op_lb_bs_openshift_cluster_api_backend_set_internal" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_api_backend_set_internal.name, null)
}

output "op_lb_bs_openshift_cluster_infra-mcs_backend_set" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set.name, null)
}

output "op_lb_bs_openshift_cluster_infra-mcs_backend_set_2" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set_2.name, null)
}

output "op_lb_bs_openshift_cluster_infra-mcs_backend_set_api_2" {
  value = try(oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set_api_2.name, null)
}

output "op_lb_openshift_exposure_infra_lb" {
  value = length(oci_load_balancer_load_balancer.openshift_exposure_infra_lb) > 0 ? oci_load_balancer_load_balancer.openshift_exposure_infra_lb[0].id : ""
}

output "op_lb_openshift_exposure_infra_lb_ip_addr" {
  value = length(oci_load_balancer_load_balancer.openshift_exposure_infra_lb) > 0 ? oci_load_balancer_load_balancer.openshift_exposure_infra_lb[0].ip_address_details[0].ip_address : ""
}

output "op_lb_bs_openshift_exposure_infra_http_backend_set" {
  value = length(oci_load_balancer_backend_set.openshift_exposure_infra_http_backend_set) > 0 ? oci_load_balancer_backend_set.openshift_exposure_infra_http_backend_set[0].name : ""
}

output "op_lb_bs_openshift_exposure_infra_https_backend_set" {
  value = length(oci_load_balancer_backend_set.openshift_exposure_infra_https_backend_set) > 0 ? oci_load_balancer_backend_set.openshift_exposure_infra_https_backend_set[0].name : ""
}
