data "oci_identity_regions" "regions" {
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

locals {
  region_map = {
    for r in data.oci_identity_regions.regions.regions :
    r.key => r.name
  }

  home_region = local.region_map[data.oci_identity_tenancy.tenancy.home_region_key]

  is_control_plane_iscsi_type = can(regex("^BM\\..*$", var.control_plane_shape))
  is_compute_iscsi_type       = can(regex("^BM\\..*$", var.compute_shape))

  current_cp_count      = length(data.oci_load_balancer_backends.openshift_api_backend.backends)
  current_compute_count = var.existing_compute_count != null ? var.existing_compute_count : length(data.oci_load_balancer_backends.openshift_apps_ingress_http.backends) - local.current_cp_count

  day_2_image_name   = format("%s-day-2", var.cluster_name)
  import_day_2_image = var.add_nodes_phase != "discover"
  compute_image_id = local.import_day_2_image ? (
    local.is_compute_iscsi_type ? module.image.op_image_openshift_image_native : module.image.op_image_openshift_image_paravirtualized
  ) : var.placeholder_image_ocid

  cluster_instance_role_tag_namespace = var.cluster_instance_role_tag_namespace != "" ? var.cluster_instance_role_tag_namespace : format("openshift-%s", var.cluster_name)
}
