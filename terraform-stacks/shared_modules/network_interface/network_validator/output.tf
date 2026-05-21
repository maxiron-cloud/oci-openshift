# VCN Details
output "vcn_details" {
  value = {
    vcn_id = data.oci_core_vcn.existing_vcn.id
  }
}

# Subnet Details
output "subnet_details" {
  value = {
    private_ocp_subnet = {
      id = data.oci_core_subnet.existing_private_ocp.id
    }
    private_bare_metal_subnet = {
      id = data.oci_core_subnet.existing_private_bare_metal.id
    }
    public_subnet = {
      id = data.oci_core_subnet.existing_public.id
    }
  }
}

# NSG Details
output "nsg_details" {
  value = {
    lb_nsg = {
      id = local.lb_nsg_id
    }
    controlplane_nsg = {
      id = local.controlplane_nsg_id
    }
    compute_nsg = {
      id = local.compute_nsg_id
    }
  }
}

# Security List Details
output "security_list_details" {
  value = {
    private_security_list = {
      id = try(data.oci_core_security_lists.existing_private.security_lists[0].id, data.oci_core_vcn.existing_vcn.default_security_list_id)
    }
    public_security_list = {
      id = try(data.oci_core_security_lists.existing_public.security_lists[0].id, data.oci_core_vcn.existing_vcn.default_security_list_id)
    }
  }
}
