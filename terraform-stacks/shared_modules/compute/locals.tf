locals {
  is_abi = var.installation_method == "Agent-based" ? true : false

  rendezvous_cp_key = try(
    one([for key, node in var.cp_node_map : key if node.index == 1]),
    null,
  )

  reserve_rendezvous_private_ip = (
    var.create_openshift_instances
    && local.is_abi
    && !var.is_control_plane_iscsi_type
    && var.rendezvous_ip != ""
    && local.rendezvous_cp_key != null
  )
}
