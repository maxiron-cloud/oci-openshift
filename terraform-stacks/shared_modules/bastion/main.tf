terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

# OCI Bastion Service — time-limited, audited SSH access to private cluster nodes.
# SSH port 22 is not open on the public Security List; use Bastion sessions instead.
resource "oci_bastion_bastion" "cluster_bastion" {
  count  = var.enable_bastion ? 1 : 0

  bastion_type     = "STANDARD"
  compartment_id   = var.compartment_ocid
  target_subnet_id = var.target_subnet_id
  name             = "${var.cluster_name}-bastion"

  client_cidr_block_allow_list = var.bastion_allowed_cidrs
  max_session_ttl_in_seconds   = 10800 # 3 hours

  defined_tags = var.defined_tags
}
