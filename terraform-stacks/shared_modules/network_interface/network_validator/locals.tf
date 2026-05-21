locals {
  use_explicit_nsgs = (
    var.existing_lb_nsg_id != "" &&
    var.existing_controlplane_nsg_id != "" &&
    var.existing_compute_nsg_id != ""
  )
  skip_legacy_security_list_validation = local.use_explicit_nsgs

  lb_nsg_id = local.use_explicit_nsgs ? var.existing_lb_nsg_id : try(
    data.oci_core_network_security_groups.existing_lb_nsgs.network_security_groups[0].id,
    "",
  )
  controlplane_nsg_id = local.use_explicit_nsgs ? var.existing_controlplane_nsg_id : try(
    data.oci_core_network_security_groups.existing_controlplane_nsgs.network_security_groups[0].id,
    "",
  )
  compute_nsg_id = local.use_explicit_nsgs ? var.existing_compute_nsg_id : try(
    data.oci_core_network_security_groups.existing_compute_nsgs.network_security_groups[0].id,
    "",
  )
}
