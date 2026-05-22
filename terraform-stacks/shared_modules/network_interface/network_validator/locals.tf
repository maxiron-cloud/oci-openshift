locals {
  use_explicit_nsgs = (
    var.existing_lb_nsg_id != "" &&
    var.existing_controlplane_nsg_id != "" &&
    var.existing_compute_nsg_id != ""
  )
  skip_legacy_security_list_validation = local.use_explicit_nsgs

  # Landing-zone brownfield: subnets/NSGs/VCN OCIDs are supplied explicitly; skip
  # list-based discovery checks that fail when ormstack cannot list in the network
  # compartment (empty API results) even though resources exist.
  brownfield_lz_network = (
    var.existing_vcn_id != "" &&
    var.existing_public_subnet_id != "" &&
    var.existing_private_ocp_subnet_id != "" &&
    var.existing_private_bare_metal_subnet_id != "" &&
    var.existing_lb_nsg_id != "" &&
    var.existing_controlplane_nsg_id != "" &&
    var.existing_compute_nsg_id != ""
  )

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

  # OCI provider returns null (not []) when list APIs are denied or fail; coalesce so
  # check conditions never call length(null). Terraform || does not short-circuit.
  ig_gateways        = coalesce(data.oci_core_internet_gateways.existing_ig.gateways, [])
  sgw_gateways       = coalesce(data.oci_core_service_gateways.existing_sgw.service_gateways, [])
  nat_gateways       = coalesce(data.oci_core_nat_gateways.existing_nat.nat_gateways, [])
  private_sec_lists  = coalesce(data.oci_core_security_lists.existing_private.security_lists, [])
  public_sec_lists   = coalesce(data.oci_core_security_lists.existing_public.security_lists, [])
  private_route_tbls = coalesce(data.oci_core_route_tables.existing_private_routes.route_tables, [])
  public_route_tbls  = coalesce(data.oci_core_route_tables.existing_public_routes.route_tables, [])
  lb_nsg_rules       = coalesce(data.oci_core_network_security_group_security_rules.existing_lb_rules.security_rules, [])
  cp_nsg_rules       = coalesce(data.oci_core_network_security_group_security_rules.existing_controlplane_rules.security_rules, [])
  compute_nsg_rules  = coalesce(data.oci_core_network_security_group_security_rules.existing_compute_rules.security_rules, [])
}
