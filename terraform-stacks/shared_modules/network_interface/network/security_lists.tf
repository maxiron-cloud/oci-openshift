resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_ocid
  display_name   = "private"
  vcn_id         = oci_core_vcn.openshift_vcn.id
  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = local.all_protocols
  }
  egress_security_rules {
    destination = local.anywhere
    protocol    = local.all_protocols
  }
  defined_tags = var.defined_tags
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  display_name   = "public"
  vcn_id         = oci_core_vcn.openshift_vcn.id
  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = local.all_protocols
  }
  # SSH (port 22) is intentionally NOT open to the internet here.
  # Use the OCI Bastion service for time-limited, audited SSH access to nodes.
  egress_security_rules {
    destination = local.anywhere
    protocol    = local.all_protocols
  }
  defined_tags = var.defined_tags
}
