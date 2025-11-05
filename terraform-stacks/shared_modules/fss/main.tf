# ============================================================================
# OCI File Storage Service (FSS) Module
# ============================================================================
# This module creates static FSS resources for OpenShift cluster storage:
# - File System: Persistent NFS-based storage
# - Mount Target: Network endpoint in the cluster subnet
# - Export: Shared access configuration with proper permissions
#
# Benefits over dynamic provisioning:
# - Resources tracked in Terraform state
# - Clean destroy operations (no orphaned resources)
# - Predictable lifecycle management
# - Consistent naming and tagging
# ============================================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

# ============================================================================
# File System
# ============================================================================

resource "oci_file_storage_file_system" "cluster_fss" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "${var.display_name_prefix}-fss"

  defined_tags = var.defined_tags

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

# ============================================================================
# Mount Target
# ============================================================================

resource "oci_file_storage_mount_target" "cluster_mount_target" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  subnet_id           = var.subnet_ocid
  display_name        = "${var.display_name_prefix}-fss-mt"

  # Attach to cluster compute NSG for network access control
  nsg_ids = [var.nsg_ocid]

  defined_tags = var.defined_tags

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

# ============================================================================
# Export
# ============================================================================

resource "oci_file_storage_export" "cluster_export" {
  export_set_id  = oci_file_storage_mount_target.cluster_mount_target.export_set_id
  file_system_id = oci_file_storage_file_system.cluster_fss.id
  path           = "/openshift"

  export_options {
    source = "10.0.0.0/16"
    access = "READ_WRITE"
    
    # identity_squash: NONE allows client user/group IDs to be preserved
    identity_squash = "NONE"
    
    # require_privileged_source_port: false allows connections from non-privileged ports
    require_privileged_source_port = false
  }
}

