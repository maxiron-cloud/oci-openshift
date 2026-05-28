# ABI rendezvous master: create before other control-plane nodes so 10.x.2.20 is not DHCP-assigned elsewhere.
resource "oci_core_instance" "control_plane_rendezvous" {
  count = local.rendezvous_first_cp ? 1 : 0

  compartment_id      = var.compartment_ocid
  availability_domain = local.rendezvous_cp_node.ad_name
  fault_domain        = var.distribute_cp_instances_across_fds ? local.rendezvous_cp_node.fault_domain : null
  display_name        = "${var.cluster_name}-master-${local.rendezvous_cp_node.index}"
  shape               = var.control_plane_shape

  defined_tags = {
    "${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}"         = "control_plane"
    "${var.openshift_attribution_tag_namespace}.${var.openshift_attribution_tag_key}" = var.openshift_tag_openshift_resource_value
  }

  create_vnic_details {
    display_name              = "${var.cluster_name}-master-${local.rendezvous_cp_node.index}"
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    nsg_ids = [
      var.op_network_security_group_cluster_controlplane_nsg,
    ]
    subnet_id  = var.op_subnet_private_ocp
    private_ip = var.rendezvous_ip
  }

  source_details {
    source_type             = "image"
    boot_volume_size_in_gbs = var.control_plane_boot_size
    boot_volume_vpus_per_gb = var.control_plane_boot_volume_vpus_per_gb
    kms_key_id              = var.kms_key_id != "" ? var.kms_key_id : null
    source_id               = var.op_image_openshift_image_paravirtualized
  }

  dynamic "shape_config" {
    for_each = [1]
    content {
      memory_in_gbs = var.control_plane_memory
      ocpus         = var.control_plane_ocpu
    }
  }

  metadata = {
    user_data = base64encode(file("${path.module}/userdata/iscsi-oci-configure-secondary-nic.sh"))
  }
}
