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

  current_region_key = [
    for r in data.oci_identity_regions.regions.regions :
    r.key if r.name == var.region
  ][0]

  # RMS Instance Principal often cannot read tenancy.home_region_key; fall back to var.region.
  home_region = try(
    local.region_map[data.oci_identity_tenancy.tenancy.home_region_key],
    var.region,
  )

  is_control_plane_iscsi_type = can(regex("^BM\\..*$", var.control_plane_shape))
  is_compute_iscsi_type       = can(regex("^BM\\..*$", var.compute_shape))
  is_infra_iscsi_type         = can(regex("^BM\\..*$", var.infra_shape))

  apps_subnet_id        = var.enable_public_apps_lb ? module.network.op_subnet_public : module.network.op_subnet_private_ocp
  apps_security_list_id = var.enable_public_apps_lb ? module.network.op_security_list_public : module.network.op_security_list_private

  existing_networking_compartment_ocid = var.use_existing_network ? var.networking_compartment_ocid : null

  openshift_installer_version = var.set_openshift_installer_version ? var.openshift_installer_version : "latest"

  # how long resource creation will be paused to allow for newly created tagging resources to reach consistency
  wait_for_new_tag_consistency_wait_time = "30s"

  # Brownfield (BYON): load balancers and bastion belong in the network compartment per landing-zone IAM.
  load_balancer_compartment_ocid = var.use_existing_network && var.networking_compartment_ocid != "" ? var.networking_compartment_ocid : var.compartment_ocid
  bastion_compartment_ocid       = var.use_existing_network && var.networking_compartment_ocid != "" ? var.networking_compartment_ocid : var.compartment_ocid

  # Landing-zone: ingress subnet for apps LB; api subnet for public API LB when provided.
  lb_public_subnet_for_apps = var.use_existing_network ? var.existing_public_subnet_id : ""
  lb_public_subnet_for_api = var.use_existing_network ? (
    var.existing_api_public_subnet_id != "" ? var.existing_api_public_subnet_id : var.existing_public_subnet_id
  ) : ""
}
