output "compute_nodes" {
  value = {
    for key, instance in oci_core_instance.compute_node : key => {
      id                  = instance.id
      display_name        = instance.display_name
      index               = var.compute_node_map[key].index
      availability_domain = instance.availability_domain
      fault_domain        = instance.fault_domain
      primary_vnic_id     = data.oci_core_vnic_attachments.compute_primary_vnic_attachments[key].vnic_attachments[0].vnic_id
      primary_mac_address = try(
        data.oci_core_vnic.compute_primary_vnic[key].mac_address,
        null,
      )
      primary_private_ip = try(
        data.oci_core_vnic.compute_primary_vnic[key].private_ip_address,
        null,
      )
      boot_volume_id = try(
        data.oci_core_boot_volume_attachments.compute_boot_volume_attachments[key].boot_volume_attachments[0].boot_volume_id,
        null,
      )
    }
  }
}
