# Reserve rendezvous IP before any control-plane instance is created so parallel
# launches cannot DHCP-assign 10.6.2.20 to another master first.
resource "oci_core_private_ip" "rendezvous" {
  count = local.reserve_rendezvous_private_ip ? 1 : 0

  # compartment_id is inferred from subnet_id in OCI provider 8.x+
  subnet_id      = var.is_control_plane_iscsi_type ? var.op_subnet_private_bare_metal : var.op_subnet_private_ocp
  ip_address     = var.rendezvous_ip
  display_name   = "${var.cluster_name}-rendezvous"
  hostname_label = "${var.cluster_name}-master-1"
}
