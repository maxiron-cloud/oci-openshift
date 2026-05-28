locals {
  is_abi = var.installation_method == "Agent-based" ? true : false

  rendezvous_cp_key = try(
    one([for key, node in var.cp_node_map : key if node.index == 1]),
    null,
  )

  rendezvous_cp_node = local.rendezvous_cp_key != null ? var.cp_node_map[local.rendezvous_cp_key] : null

  # Launch master-1 with static rendezvous IP before other masters so DHCP cannot take .20.
  # oci_core_private_ip only works on OCI "learning" subnets; use instance private_ip instead.
  rendezvous_first_cp = (
    var.create_openshift_instances
    && local.is_abi
    && !var.is_control_plane_iscsi_type
    && var.rendezvous_ip != ""
    && local.rendezvous_cp_key != null
    && local.rendezvous_cp_node != null
  )

  cp_node_map_parallel = local.rendezvous_first_cp ? {
    for k, v in var.cp_node_map : k => v if k != local.rendezvous_cp_key
  } : var.cp_node_map

  control_plane_instances = merge(
    oci_core_instance.control_plane_node,
    {
      for _ in oci_core_instance.control_plane_rendezvous :
      (local.rendezvous_cp_key) => oci_core_instance.control_plane_rendezvous[0]
    },
  )
}
